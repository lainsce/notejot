import Foundation
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// HTML <-> NSAttributedString over the tag set permitted by previous builds.
/// Attributes are stripped and dangerous elements are removed with their content.
/// The system HTML importer is deliberately avoided because it loads WebKit.
@MainActor
public enum HTMLMapper {
    private static let inlineTags: Set<String> = [
        "b", "strong", "i", "em", "u", "s", "strike", "span", "code",
    ]
    private static let paragraphTags: Set<String> = [
        "p", "div", "li", "h1", "h2", "h3", "blockquote", "pre",
    ]
    private static let listTags: Set<String> = ["ul", "ol"]
    static let dropWithContent: Set<String> = [
        "script", "style", "iframe", "object", "embed", "template", "link", "meta",
    ]
    private static let headingLevels: [String: Int] = ["h1": 1, "h2": 2, "h3": 3]
    private static let inlineStyleKeyPaths: [String: WritableKeyPath<Style, Bool>] = [
        "b": \.bold, "strong": \.bold,
        "i": \.italic, "em": \.italic,
        "u": \.underline,
        "s": \.strikethrough, "strike": \.strikethrough,
        "code": \.isMonospaced,
    ]
    private static let paragraphFlagKeyPaths: [String: WritableKeyPath<Style, Bool>] = [
        "li": \.isListItem,
        "blockquote": \.isQuoted,
        "pre": \.isMonospaced,
    ]

    public static var bodyFont: NotejotFont {
        PlatformTypography.bodyFont
    }

    public static func font(forHeadingLevel level: Int) -> NotejotFont {
        PlatformTypography.headingFont(level: level)
    }

    private struct Style {
        var bold = false
        var italic = false
        var underline = false
        var strikethrough = false
        var headingLevel = 0
        var isListItem = false
        var isMonospaced = false
        var isQuoted = false
    }

    public static func escape(_ text: String) -> String {
        text.replacing("&", with: "&amp;")
            .replacing("<", with: "&lt;")
            .replacing(">", with: "&gt;")
    }

    public static func textToHTML(_ text: String) -> String {
        guard !text.isEmpty else { return "" }
        return text.split(separator: "\n", omittingEmptySubsequences: false)
            .map { "<p>\(escape(String($0)))</p>" }
            .joined()
    }

    public static func attributedString(fromHTML html: String) -> NSAttributedString {
        guard !html.isEmpty else { return NSAttributedString() }

        let output = NSMutableAttributedString()
        var styleStack = [Style()]
        // Keep empty block elements distinguishable from an ordinary block
        // separator. Without this stack, consecutive <p></p> elements are
        // collapsed by appendParagraphBreak() and authored blank lines vanish
        // when a note is reloaded.
        var paragraphContentStack = [Bool]()
        parseHTML(
            html,
            output: output,
            styleStack: &styleStack,
            paragraphContentStack: &paragraphContentStack
        )

        // Closing the final block adds a separator, not a user-authored blank line.
        if output.string.hasSuffix("\n") {
            output.deleteCharacters(in: NSRange(location: output.length - 1, length: 1))
        }
        return output
    }

    private static func parseHTML(
        _ html: String,
        output: NSMutableAttributedString,
        styleStack: inout [Style],
        paragraphContentStack: inout [Bool]
    ) {
        var index = html.startIndex
        while index < html.endIndex {
            if html[index] == "<" {
                consumeTag(
                    in: html,
                    index: &index,
                    output: output,
                    styleStack: &styleStack,
                    paragraphContentStack: &paragraphContentStack
                )
            } else {
                consumeText(
                    in: html,
                    index: &index,
                    output: output,
                    styleStack: styleStack,
                    paragraphContentStack: &paragraphContentStack
                )
            }
        }
    }

    private static func consumeText(
        in html: String,
        index: inout String.Index,
        output: NSMutableAttributedString,
        styleStack: [Style],
        paragraphContentStack: inout [Bool]
    ) {
        let nextTag = html[index...].firstIndex(of: "<") ?? html.endIndex
        appendText(
            String(html[index..<nextTag]),
            output: output,
            styleStack: styleStack,
            paragraphContentStack: &paragraphContentStack
        )
        index = nextTag
    }

    private static func consumeTag(
        in html: String,
        index: inout String.Index,
        output: NSMutableAttributedString,
        styleStack: inout [Style],
        paragraphContentStack: inout [Bool]
    ) {
        guard let close = html[index...].firstIndex(of: ">") else {
            appendText(
                String(html[index...]),
                output: output,
                styleStack: styleStack,
                paragraphContentStack: &paragraphContentStack
            )
            index = html.endIndex
            return
        }

        let rawTag = String(html[html.index(after: index)..<close])
        index = html.index(after: close)
        let isClosing = rawTag.hasPrefix("/")
        let name = tagName(from: rawTag)

        if consumeSpecialTag(
            name,
            isClosing: isClosing,
            in: html,
            index: &index,
            output: output,
            styleStack: &styleStack,
            paragraphContentStack: &paragraphContentStack
        ) { return }

        if inlineTags.contains(name) {
            handleInlineTag(name, isClosing: isClosing, styleStack: &styleStack)
        }
        // Unknown tags are deliberately unwrapped: their text remains.
    }

    private static func tagName(from rawTag: String) -> String {
        rawTag
            .drop(while: { $0 == "/" })
            .prefix(while: { !$0.isWhitespace && $0 != "/" })
            .lowercased()
    }

    private static func consumeSpecialTag(
        _ name: String,
        isClosing: Bool,
        in html: String,
        index: inout String.Index,
        output: NSMutableAttributedString,
        styleStack: inout [Style],
        paragraphContentStack: inout [Bool]
    ) -> Bool {
        if dropWithContent.contains(name) {
            if !isClosing,
               let end = html.range(
                   of: "</\(name)>",
                   options: .caseInsensitive,
                   range: index..<html.endIndex
               ) { index = end.upperBound }
            return true
        }
        if name == "br" {
            markParagraphContent(&paragraphContentStack)
            appendParagraphBreak(to: output)
            return true
        }
        return consumeBlockTag(
            name,
            isClosing: isClosing,
            output: output,
            styleStack: &styleStack,
            paragraphContentStack: &paragraphContentStack
        )
    }

    private static func consumeBlockTag(
        _ name: String,
        isClosing: Bool,
        output: NSMutableAttributedString,
        styleStack: inout [Style],
        paragraphContentStack: inout [Bool]
    ) -> Bool {
        if listTags.contains(name) {
            handleListTag(isClosing: isClosing, styleStack: &styleStack)
            return true
        }
        if paragraphTags.contains(name) {
            handleParagraphTag(
                name,
                isClosing: isClosing,
                output: output,
                styleStack: &styleStack,
                paragraphContentStack: &paragraphContentStack
            )
            return true
        }
        return false
    }

    private static func appendParagraphBreak(
        to output: NSMutableAttributedString,
        force: Bool = false
    ) {
        guard force || !output.string.hasSuffix("\n") else { return }
        // A bare newline has no font metrics, so AppKit gives an empty
        // paragraph a shorter fallback line fragment. Carry the editor's
        // body metrics on separators to keep authored blank lines visible
        // at the same height as surrounding paragraphs.
        output.append(
            NSAttributedString(
                string: "\n",
                attributes: [
                    .font: bodyFont,
                    .paragraphStyle: NSParagraphStyle.default,
                ]
            )
        )
    }

    private static func markParagraphContent(_ stack: inout [Bool]) {
        guard !stack.isEmpty else { return }
        stack[stack.count - 1] = true
    }

    private static func handleListTag(isClosing: Bool, styleStack: inout [Style]) {
        if isClosing {
            if styleStack.count > 1 { styleStack.removeLast() }
        } else {
            styleStack.append(styleStack.last ?? Style())
        }
    }

    private static func handleParagraphTag(
        _ name: String,
        isClosing: Bool,
        output: NSMutableAttributedString,
        styleStack: inout [Style],
        paragraphContentStack: inout [Bool]
    ) {
        if isClosing {
            closeParagraph(output: output, styleStack: &styleStack, paragraphContentStack: &paragraphContentStack)
            return
        }

        if output.length > 0 { appendParagraphBreak(to: output) }
        styleStack.append(paragraphStyle(named: name, base: currentStyle(styleStack)))
        paragraphContentStack.append(false)
    }

    private static func closeParagraph(
        output: NSMutableAttributedString,
        styleStack: inout [Style],
        paragraphContentStack: inout [Bool]
    ) {
        let hasContent = paragraphContentStack.popLast() ?? true
        if styleStack.count > 1 { styleStack.removeLast() }
        appendParagraphBreak(to: output, force: !hasContent)
    }

    private static func currentStyle(_ styleStack: [Style]) -> Style {
        styleStack.last ?? Style()
    }

    private static func paragraphStyle(named name: String, base: Style) -> Style {
        var style = base
        if let level = headingLevels[name] {
            style.headingLevel = level
        } else if let keyPath = paragraphFlagKeyPaths[name] {
            style[keyPath: keyPath] = true
        }
        return style
    }

    private static func handleInlineTag(
        _ name: String,
        isClosing: Bool,
        styleStack: inout [Style]
    ) {
        if isClosing {
            if styleStack.count > 1 { styleStack.removeLast() }
            return
        }

        var style = currentStyle(styleStack)
        if let keyPath = inlineStyleKeyPaths[name] { style[keyPath: keyPath] = true }
        styleStack.append(style)
    }

    private static func appendText(
        _ encodedText: String,
        output: NSMutableAttributedString,
        styleStack: [Style],
        paragraphContentStack: inout [Bool]
    ) {
        let text = unescape(encodedText)
        guard !text.isEmpty else { return }
        markParagraphContent(&paragraphContentStack)
        let style = styleStack.last ?? Style()
        let font = textFont(for: style)
        let paragraphStyle = paragraphStyle(for: style)
        let attributes = textAttributes(for: style, font: font, paragraphStyle: paragraphStyle)
        output.append(NSAttributedString(string: text, attributes: attributes))
    }

    private static func textFont(for style: Style) -> NotejotFont {
        let baseFont = baseFont(for: style)
        let traits = traits(for: style)
        return traits.isEmpty ? baseFont : PlatformTypography.applying(traits, to: baseFont)
    }

    private static func baseFont(for style: Style) -> NotejotFont {
        if style.headingLevel > 0 {
            return Self.font(forHeadingLevel: style.headingLevel)
        } else if style.isMonospaced {
            return PlatformTypography.monospacedFont
        } else {
            return bodyFont
        }
    }

    private static func traits(for style: Style) -> NotejotFontTraits {
        var traits: NotejotFontTraits = []
        if style.bold { traits.insert(PlatformTypography.boldTrait) }
        if style.italic { traits.insert(PlatformTypography.italicTrait) }
        return traits
    }

    private static func paragraphStyle(for style: Style) -> NSMutableParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        if style.isListItem {
            paragraphStyle.textLists = [NSTextList(markerFormat: .disc, options: 0)]
            paragraphStyle.firstLineHeadIndent = 12
            paragraphStyle.headIndent = 24
        } else if style.isQuoted {
            paragraphStyle.firstLineHeadIndent = 24
            paragraphStyle.headIndent = 24
        }
        return paragraphStyle
    }

    private static func textAttributes(
        for style: Style,
        font: NotejotFont,
        paragraphStyle: NSMutableParagraphStyle
    ) -> [NSAttributedString.Key: NSObject] {
        var attributes: [NSAttributedString.Key: NSObject] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
        ]
        if style.headingLevel > 0 { attributes[.notejotHeadingLevel] = NSNumber(value: style.headingLevel) }
        if style.underline { attributes[.underlineStyle] = NSNumber(value: NSUnderlineStyle.single.rawValue) }
        if style.strikethrough { attributes[.strikethroughStyle] = NSNumber(value: NSUnderlineStyle.single.rawValue) }
        return attributes
    }

}
