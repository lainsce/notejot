import SwiftUI

#if canImport(UIKit)
import NotejotCore
import UIKit

@MainActor
final class EditorFormattingController {
    fileprivate weak var textView: UITextView?

    enum Style { case bold, italic, underline, strikethrough, bulletList, heading(Int) }

    func apply(_ style: Style) {
        guard let target = editingTarget(for: style) else { return }
        let textView = target.textView
        let storage = target.storage

        let range = textView.selectedRange
        guard range.length > 0 else {
            applyToTypingAttributes(style, textView: textView)
            return
        }

        guard shouldChange(textView, in: range) else { return }

        storage.beginEditing()
        applyCharacterStyle(style, range: range, storage: storage)
        storage.endEditing()
        textView.delegate?.textViewDidChange?(textView)
    }

    private struct EditingTarget {
        let textView: UITextView
        let storage: NSTextStorage
    }

    private func editingTarget(for style: Style) -> EditingTarget? {
        guard let textView else { return nil }
        let storage = textView.textStorage
        guard !applyParagraphStyleIfNeeded(style, textView: textView, storage: storage) else { return nil }
        return EditingTarget(textView: textView, storage: storage)
    }

    private func shouldChange(_ textView: UITextView, in range: NSRange) -> Bool {
        textView.delegate?.textView?(
            textView,
            shouldChangeTextIn: range,
            replacementText: ""
        ) ?? true
    }

    private func applyParagraphStyleIfNeeded(
        _ style: Style,
        textView: UITextView,
        storage: NSTextStorage
    ) -> Bool {
        switch style {
        case .bulletList:
            applyBulletList(textView: textView, storage: storage)
            return true
        case .heading(let level):
            applyHeading(level: level, textView: textView, storage: storage)
            return true
        default:
            return false
        }
    }

    private func applyCharacterStyle(_ style: Style, range: NSRange, storage: NSTextStorage) {
        if applyFontStyle(style, range: range, storage: storage) { return }
        applyBinaryStyle(style, range: range, storage: storage)
    }

    private func applyFontStyle(_ style: Style, range: NSRange, storage: NSTextStorage) -> Bool {
        switch style {
        case .bold:
            enumerateFonts(in: range, storage: storage) { EditorBoldStyler.toggled($0) }
            return true
        case .italic:
            enumerateFonts(in: range, storage: storage) { EditorBoldStyler.toggledItalic($0) }
            return true
        default:
            return false
        }
    }

    private func enumerateFonts(
        in range: NSRange,
        storage: NSTextStorage,
        transform: @escaping (UIFont) -> UIFont
    ) {
        storage.enumerateAttribute(.font, in: range) { value, subrange, _ in
            let font = value as? UIFont ?? HTMLMapper.bodyFont
            storage.addAttribute(.font, value: transform(font), range: subrange)
        }
    }

    private func applyBinaryStyle(_ style: Style, range: NSRange, storage: NSTextStorage) {
        switch style {
        case .underline:
            toggleBinaryAttribute(.underlineStyle, in: range, storage: storage)
        case .strikethrough:
            toggleBinaryAttribute(.strikethroughStyle, in: range, storage: storage)
        default:
            break
        }
    }

    private func toggleBinaryAttribute(
        _ key: NSAttributedString.Key,
        in range: NSRange,
        storage: NSTextStorage
    ) {
        var allSet = true
        storage.enumerateAttribute(key, in: range) { value, _, stop in
            if (value as? Int ?? 0) == 0 {
                allSet = false
                stop.pointee = true
            }
        }
        if allSet {
            storage.removeAttribute(key, range: range)
        } else {
            storage.addAttribute(key, value: NSUnderlineStyle.single.rawValue, range: range)
        }
    }

    private func applyToTypingAttributes(_ style: Style, textView: UITextView) {
        var attributes: [NSAttributedString.Key: NSObject] = textView.typingAttributes.compactMapValues { $0 as? NSObject }
        if !applyFontTypingAttributes(style, to: &attributes) {
            applyBinaryTypingAttributes(style, to: &attributes)
        }
        textView.typingAttributes = attributes
    }

    private func applyFontTypingAttributes(
        _ style: Style,
        to attributes: inout [NSAttributedString.Key: NSObject]
    ) -> Bool {
        switch style {
        case .bold:
            attributes[.font] = EditorBoldStyler.toggled(typingFont(from: attributes))
            return true
        case .italic:
            attributes[.font] = EditorBoldStyler.toggledItalic(typingFont(from: attributes))
            return true
        default:
            return false
        }
    }

    private func typingFont(from attributes: [NSAttributedString.Key: NSObject]) -> UIFont {
        attributes[.font] as? UIFont ?? HTMLMapper.bodyFont
    }

    private func applyBinaryTypingAttributes(
        _ style: Style,
        to attributes: inout [NSAttributedString.Key: NSObject]
    ) {
        switch style {
        case .underline:
            toggleTypingAttribute(.underlineStyle, in: &attributes)
        case .strikethrough:
            toggleTypingAttribute(.strikethroughStyle, in: &attributes)
        default:
            break
        }
    }

    private func toggleTypingAttribute(
        _ key: NSAttributedString.Key,
        in attributes: inout [NSAttributedString.Key: NSObject]
    ) {
        let isSet = (attributes[key] as? NSNumber)?.intValue != 0
        attributes[key] = isSet ? nil : NSNumber(value: NSUnderlineStyle.single.rawValue)
    }

    private func applyBulletList(textView: UITextView, storage: NSTextStorage) {
        let selectedRange = textView.selectedRange
        let paragraphRange = (storage.string as NSString).paragraphRange(for: selectedRange)
        var hasList = false
        storage.enumerateAttribute(.paragraphStyle, in: paragraphRange) { value, _, stop in
            if let style = value as? NSParagraphStyle, !style.textLists.isEmpty {
                hasList = true
                stop.pointee = true
            }
        }

        storage.beginEditing()
        if hasList {
            storage.addAttribute(.paragraphStyle, value: NSParagraphStyle.default, range: paragraphRange)
        } else {
            let list = NSTextList(markerFormat: .disc, options: 0)
            let style = NSMutableParagraphStyle()
            style.textLists = [list]
            style.firstLineHeadIndent = 0
            style.headIndent = 22
            storage.addAttribute(.paragraphStyle, value: style, range: paragraphRange)
        }
        storage.endEditing()
        textView.delegate?.textViewDidChange?(textView)
    }

    private func applyHeading(level: Int, textView: UITextView, storage: NSTextStorage) {
        let selectedRange = textView.selectedRange
        let paragraphRange = (storage.string as NSString).paragraphRange(for: selectedRange)
        let baseFont = HTMLMapper.font(forHeadingLevel: level)

        storage.beginEditing()
        applyHeadingFonts(baseFont: baseFont, level: level, range: paragraphRange, storage: storage)
        applyHeadingAttribute(level: level, range: paragraphRange, storage: storage)
        storage.endEditing()
        textView.delegate?.textViewDidChange?(textView)
    }

    private func applyHeadingFonts(
        baseFont: UIFont,
        level: Int,
        range: NSRange,
        storage: NSTextStorage
    ) {
        storage.enumerateAttribute(.font, in: range) { value, subrange, _ in
            let source = value as? UIFont ?? HTMLMapper.bodyFont
            var traits = source.fontDescriptor.symbolicTraits
            if level > 0 { traits.insert(PlatformTypography.boldTrait) } else { traits.remove(PlatformTypography.boldTrait) }
            storage.addAttribute(
                .font,
                value: PlatformTypography.applying(traits, to: baseFont),
                range: subrange
            )
        }
    }

    private func applyHeadingAttribute(level: Int, range: NSRange, storage: NSTextStorage) {
        if level > 0 {
            storage.addAttribute(.notejotHeadingLevel, value: level, range: range)
        } else {
            storage.removeAttribute(.notejotHeadingLevel, range: range)
        }
    }
}

struct EditorTextView: UIViewRepresentable {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Binding var text: NSAttributedString
    let formatter: EditorFormattingController

    func makeCoordinator() -> Coordinator {
        Coordinator(self, dynamicTypeSize: dynamicTypeSize)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.allowsEditingTextAttributes = true
        textView.backgroundColor = .clear
        textView.textColor = .label
        textView.font = HTMLMapper.bodyFont
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        textView.attributedText = text
        formatter.textView = textView
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.parent = self
        formatter.textView = textView
        if context.coordinator.dynamicTypeSize != dynamicTypeSize {
            context.coordinator.dynamicTypeSize = dynamicTypeSize
            let selectedRange = textView.selectedRange
            let html = HTMLMapper.html(from: textView.attributedText)
            let rescaledText = HTMLMapper.attributedString(fromHTML: html)
            textView.attributedText = rescaledText
            let location = min(selectedRange.location, rescaledText.length)
            let remainingLength = rescaledText.length - location
            textView.selectedRange = NSRange(
                location: location,
                length: min(selectedRange.length, remainingLength)
            )
            Task { @MainActor in
                await Task.yield()
                context.coordinator.parent.text = rescaledText
            }
            return
        }
        guard !textView.isFirstResponder else { return }
        guard !textView.attributedText.isEqual(to: text) else { return }
        textView.attributedText = text
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: EditorTextView
        var dynamicTypeSize: DynamicTypeSize

        init(_ parent: EditorTextView, dynamicTypeSize: DynamicTypeSize) {
            self.parent = parent
            self.dynamicTypeSize = dynamicTypeSize
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.attributedText
        }
    }
}
#endif
