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
    private static let dropWithContent: Set<String> = [
        "script", "style", "iframe", "object", "embed", "template", "link", "meta",
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
        var index = html.startIndex

        func appendParagraphBreak(force: Bool = false) {
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

        func markParagraphContent() {
            guard !paragraphContentStack.isEmpty else { return }
            paragraphContentStack[paragraphContentStack.count - 1] = true
        }

        func appendText(_ encodedText: String) {
            let text = unescape(encodedText)
            guard !text.isEmpty else { return }
            markParagraphContent()
            let style = styleStack.last ?? Style()

            var font: NotejotFont
            if style.headingLevel > 0 {
                font = Self.font(forHeadingLevel: style.headingLevel)
            } else if style.isMonospaced {
                font = PlatformTypography.monospacedFont
            } else {
                font = bodyFont
            }

            var traits: NotejotFontTraits = []
            if style.bold { traits.insert(PlatformTypography.boldTrait) }
            if style.italic { traits.insert(PlatformTypography.italicTrait) }
            if !traits.isEmpty {
                font = PlatformTypography.applying(traits, to: font)
            }

            let paragraphStyle = NSMutableParagraphStyle()
            if style.isListItem {
                paragraphStyle.textLists = [NSTextList(markerFormat: .disc, options: 0)]
                paragraphStyle.firstLineHeadIndent = 12
                paragraphStyle.headIndent = 24
            } else if style.isQuoted {
                paragraphStyle.firstLineHeadIndent = 24
                paragraphStyle.headIndent = 24
            }

            var attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .paragraphStyle: paragraphStyle,
            ]
            if style.headingLevel > 0 {
                attributes[.notejotHeadingLevel] = style.headingLevel
            }
            if style.underline {
                attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
            }
            if style.strikethrough {
                attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            }
            output.append(NSAttributedString(string: text, attributes: attributes))
        }

        while index < html.endIndex {
            guard html[index] == "<" else {
                let nextTag = html[index...].firstIndex(of: "<") ?? html.endIndex
                appendText(String(html[index..<nextTag]))
                index = nextTag
                continue
            }

            guard let close = html[index...].firstIndex(of: ">") else {
                appendText(String(html[index...]))
                break
            }

            let rawTag = String(html[html.index(after: index)..<close])
            index = html.index(after: close)
            let isClosing = rawTag.hasPrefix("/")
            let name = rawTag
                .drop(while: { $0 == "/" })
                .prefix(while: { !$0.isWhitespace && $0 != "/" })
                .lowercased()

            if dropWithContent.contains(name) {
                if !isClosing,
                   let end = html.range(
                       of: "</\(name)>",
                       options: .caseInsensitive,
                       range: index..<html.endIndex
                   ) {
                    index = end.upperBound
                }
                continue
            }

            if name == "br" {
                markParagraphContent()
                appendParagraphBreak()
                continue
            }

            if listTags.contains(name) {
                if isClosing {
                    if styleStack.count > 1 { styleStack.removeLast() }
                } else {
                    styleStack.append(styleStack.last ?? Style())
                }
                continue
            }

            if paragraphTags.contains(name) {
                if isClosing {
                    let hasContent = paragraphContentStack.popLast() ?? true
                    if styleStack.count > 1 { styleStack.removeLast() }
                    appendParagraphBreak(force: !hasContent)
                } else {
                    if output.length > 0 { appendParagraphBreak() }
                    var style = styleStack.last ?? Style()
                    switch name {
                    case "h1": style.headingLevel = 1
                    case "h2": style.headingLevel = 2
                    case "h3": style.headingLevel = 3
                    case "li": style.isListItem = true
                    case "blockquote": style.isQuoted = true
                    case "pre": style.isMonospaced = true
                    default: break
                    }
                    styleStack.append(style)
                    paragraphContentStack.append(false)
                }
                continue
            }

            if inlineTags.contains(name) {
                if isClosing {
                    if styleStack.count > 1 { styleStack.removeLast() }
                } else {
                    var style = styleStack.last ?? Style()
                    switch name {
                    case "b", "strong": style.bold = true
                    case "i", "em": style.italic = true
                    case "u": style.underline = true
                    case "s", "strike": style.strikethrough = true
                    case "code": style.isMonospaced = true
                    default: break
                    }
                    styleStack.append(style)
                }
            }
            // Unknown tags are deliberately unwrapped: their text remains.
        }

        // Closing the final block adds a separator, not a user-authored blank line.
        if output.string.hasSuffix("\n") {
            output.deleteCharacters(in: NSRange(location: output.length - 1, length: 1))
        }
        return output
    }

    /// Emits only markup the editor can create: paragraphs, headings, lists,
    /// bold, italic, underline, and strikethrough.
    public static func html(from attributedString: NSAttributedString) -> String {
        guard attributedString.length > 0 else { return "" }

        let string = attributedString.string as NSString
        var paragraphs: [String] = []
        var location = 0

        while location < string.length {
            let fullRange = string.paragraphRange(for: NSRange(location: location, length: 0))
            var contentRange = fullRange
            while contentRange.length > 0 {
                let finalCharacter = string.character(at: NSMaxRange(contentRange) - 1)
                guard finalCharacter == 10 || finalCharacter == 13 else { break }
                contentRange.length -= 1
            }
            paragraphs.append(htmlParagraph(from: attributedString, range: contentRange, string: string))
            location = NSMaxRange(fullRange)
        }

        if string.hasSuffix("\n") {
            paragraphs.append("<p></p>")
        }

        var output = ""
        var isListOpen = false
        for paragraph in paragraphs {
            if paragraph.hasPrefix("<li>") {
                if !isListOpen {
                    output += "<ul>"
                    isListOpen = true
                }
                output += paragraph
            } else {
                if isListOpen {
                    output += "</ul>"
                    isListOpen = false
                }
                output += paragraph
            }
        }
        if isListOpen { output += "</ul>" }
        return output
    }

    public static func plainTextPreview(fromHTML html: String) -> String {
        var result = html
        for tag in dropWithContent {
            while let openRange = result.range(of: "<\(tag)", options: .caseInsensitive),
                  let closeRange = result.range(
                      of: "</\(tag)>",
                      options: .caseInsensitive,
                      range: openRange.lowerBound..<result.endIndex
                  ) {
                result.removeSubrange(openRange.lowerBound..<closeRange.upperBound)
            }
        }
        while let open = result.range(of: "<"),
              let close = result.range(of: ">", range: open.upperBound..<result.endIndex) {
            result.removeSubrange(open.lowerBound..<close.upperBound)
        }
        return unescape(result)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func unescape(_ text: String) -> String {
        text.replacing("&lt;", with: "<")
            .replacing("&gt;", with: ">")
            .replacing("&nbsp;", with: "\u{00A0}")
            .replacing("&quot;", with: "\"")
            .replacing("&#39;", with: "'")
            .replacing("&amp;", with: "&")
    }

    private static func htmlParagraph(
        from attributedString: NSAttributedString,
        range: NSRange,
        string: NSString
    ) -> String {
        guard range.length > 0 else { return "<p></p>" }

        let paragraphAttributes = attributedString.attributes(at: range.location, effectiveRange: nil)
        let headingLevel = paragraphAttributes[.notejotHeadingLevel] as? Int ?? 0
        let paragraphStyle = paragraphAttributes[.paragraphStyle] as? NSParagraphStyle
        let isListItem = paragraphStyle?.textLists.isEmpty == false
        var innerHTML = ""

        attributedString.enumerateAttributes(in: range) { attributes, runRange, _ in
            var piece = escape(string.substring(with: runRange))
            let font = attributes[.font] as? NotejotFont ?? bodyFont
            let traits = font.fontDescriptor.symbolicTraits
            if (attributes[.strikethroughStyle] as? Int ?? 0) != 0 {
                piece = "<s>\(piece)</s>"
            }
            if (attributes[.underlineStyle] as? Int ?? 0) != 0 {
                piece = "<u>\(piece)</u>"
            }
            if traits.contains(PlatformTypography.italicTrait) { piece = "<i>\(piece)</i>" }
            if traits.contains(PlatformTypography.boldTrait), headingLevel == 0 {
                piece = "<b>\(piece)</b>"
            }
            innerHTML += piece
        }

        if isListItem { return "<li>\(innerHTML)</li>" }
        if headingLevel == 1 { return "<h1>\(innerHTML)</h1>" }
        if headingLevel == 2 { return "<h2>\(innerHTML)</h2>" }
        if headingLevel == 3 { return "<h3>\(innerHTML)</h3>" }
        return "<p>\(innerHTML)</p>"
    }
}
