import Foundation
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

extension HTMLMapper {
    /// Emits only markup the editor can create: paragraphs, headings, lists,
    /// bold, italic, underline, and strikethrough.
    public static func html(from attributedString: NSAttributedString) -> String {
        guard attributedString.length > 0 else { return "" }

        let string = attributedString.string as NSString
        var paragraphs = htmlParagraphs(from: attributedString, string: string)
        if string.hasSuffix("\n") {
            paragraphs.append("<p></p>")
        }
        return wrapListParagraphs(paragraphs)
    }

    private static func htmlParagraphs(
        from attributedString: NSAttributedString,
        string: NSString
    ) -> [String] {
        var paragraphs: [String] = []
        var location = 0
        while location < string.length {
            let fullRange = string.paragraphRange(for: NSRange(location: location, length: 0))
            let contentRange = trimmedParagraphRange(fullRange, in: string)
            paragraphs.append(htmlParagraph(from: attributedString, range: contentRange, string: string))
            location = NSMaxRange(fullRange)
        }
        return paragraphs
    }

    private static func trimmedParagraphRange(_ range: NSRange, in string: NSString) -> NSRange {
        var contentRange = range
        while contentRange.length > 0 {
            let finalCharacter = string.character(at: NSMaxRange(contentRange) - 1)
            guard finalCharacter == 10 || finalCharacter == 13 else { break }
            contentRange.length -= 1
        }
        return contentRange
    }

    private static func wrapListParagraphs(_ paragraphs: [String]) -> String {
        var output = ""
        var isListOpen = false
        for paragraph in paragraphs {
            appendParagraph(paragraph, output: &output, isListOpen: &isListOpen)
        }
        if isListOpen { output += "</ul>" }
        return output
    }

    private static func appendParagraph(
        _ paragraph: String,
        output: inout String,
        isListOpen: inout Bool
    ) {
        if paragraph.hasPrefix("<li>") {
            if !isListOpen {
                output += "<ul>"
                isListOpen = true
            }
            output += paragraph
            return
        }
        if isListOpen {
            output += "</ul>"
            isListOpen = false
        }
        output += paragraph
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

    static func unescape(_ text: String) -> String {
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

        let paragraphAttributes = attributedString
            .attributes(at: range.location, effectiveRange: nil)
            .compactMapValues { $0 as? NSObject }
        let headingLevel = (paragraphAttributes[.notejotHeadingLevel] as? NSNumber)?.intValue ?? 0
        let paragraphStyle = paragraphAttributes[.paragraphStyle] as? NSParagraphStyle
        let isListItem = paragraphStyle?.textLists.isEmpty == false
        var innerHTML = ""

        attributedString.enumerateAttributes(in: range) { attributes, runRange, _ in
            innerHTML += htmlRun(
                attributes: attributes.compactMapValues { $0 as? NSObject },
                text: string.substring(with: runRange),
                headingLevel: headingLevel
            )
        }
        return paragraphMarkup(innerHTML: innerHTML, headingLevel: headingLevel, isListItem: isListItem)
    }

    private static func htmlRun(
        attributes: [NSAttributedString.Key: NSObject],
        text: String,
        headingLevel: Int
    ) -> String {
        var piece = escape(text)
        let font = attributedFont(from: attributes)
        let traits = font.fontDescriptor.symbolicTraits
        piece = decorated(piece, attributes: attributes)
        if traits.contains(PlatformTypography.italicTrait) { piece = "<i>\(piece)</i>" }
        if shouldBold(traits: traits, headingLevel: headingLevel) { piece = "<b>\(piece)</b>" }
        return piece
    }

    private static func decorated(
        _ piece: String,
        attributes: [NSAttributedString.Key: NSObject]
    ) -> String {
        var value = piece
        if attributeIsSet(.strikethroughStyle, in: attributes) { value = "<s>\(value)</s>" }
        if attributeIsSet(.underlineStyle, in: attributes) { value = "<u>\(value)</u>" }
        return value
    }

    private static func attributedFont(from attributes: [NSAttributedString.Key: NSObject]) -> NotejotFont {
        if let font = attributes[.font] as? NotejotFont { return font }
        return bodyFont
    }

    private static func attributeIsSet(
        _ key: NSAttributedString.Key,
        in attributes: [NSAttributedString.Key: NSObject]
    ) -> Bool {
        guard let value = attributes[key] as? NSNumber else { return false }
        return value.intValue != 0
    }

    private static func shouldBold(
        traits: NotejotFontTraits,
        headingLevel: Int
    ) -> Bool {
        headingLevel == 0 && traits.contains(PlatformTypography.boldTrait)
    }

    private static func paragraphMarkup(
        innerHTML: String,
        headingLevel: Int,
        isListItem: Bool
    ) -> String {
        if isListItem { return "<li>\(innerHTML)</li>" }
        if let tag = [1: "h1", 2: "h2", 3: "h3"][headingLevel] {
            return "<\(tag)>\(innerHTML)</\(tag)>"
        }
        return "<p>\(innerHTML)</p>"
    }
}
