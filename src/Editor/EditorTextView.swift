import SwiftUI
#if canImport(AppKit)
import AppKit
import NotejotCore

@MainActor
final class EditorFormattingController {
    fileprivate weak var textView: NSTextView?

    enum Style { case bold, italic, underline, strikethrough, bulletList, heading(Int) }

    func apply(_ style: Style) {
        guard let tv = textView, let storage = tv.textStorage else { return }

        // Paragraph-level styles always apply to the full paragraph at/around the caret.
        switch style {
        case .bulletList:
            applyBulletList(textView: tv, storage: storage)
            return
        case .heading(let level):
            applyHeading(level: level, textView: tv, storage: storage)
            return
        default:
            break
        }

        // Character-level styles: no selection → set typing attributes only.
        let range = tv.selectedRange()
        guard range.length > 0 else {
            applyToTypingAttributes(style, textView: tv)
            return
        }

        guard tv.shouldChangeText(in: range, replacementString: nil) else { return }
        storage.beginEditing()
        switch style {
        case .bold:
            storage.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
                let font = value as? NSFont ?? HTMLMapper.bodyFont
                storage.addAttribute(.font, value: EditorBoldStyler.toggled(font), range: subrange)
            }
        case .italic:
            storage.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
                let font = value as? NSFont ?? HTMLMapper.bodyFont
                storage.addAttribute(.font, value: EditorBoldStyler.toggledItalic(font), range: subrange)
            }
        case .underline:
            toggleBinaryAttribute(.underlineStyle, in: range, storage: storage)
        case .strikethrough:
            toggleBinaryAttribute(.strikethroughStyle, in: range, storage: storage)
        case .bulletList, .heading:
            break
        }
        storage.endEditing()
        tv.didChangeText()
    }

    private func toggleBinaryAttribute(_ key: NSAttributedString.Key, in range: NSRange, storage: NSTextStorage) {
        var allSet = true
        storage.enumerateAttribute(key, in: range, options: []) { value, _, stop in
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

    private func applyToTypingAttributes(_ style: Style, textView tv: NSTextView) {
        var attrs = tv.typingAttributes
        switch style {
        case .bold:
            let font = attrs[.font] as? NSFont ?? HTMLMapper.bodyFont
            attrs[.font] = EditorBoldStyler.toggled(font)
        case .italic:
            let font = attrs[.font] as? NSFont ?? HTMLMapper.bodyFont
            attrs[.font] = EditorBoldStyler.toggledItalic(font)
        case .underline:
            let has = (attrs[.underlineStyle] as? Int ?? 0) != 0
            attrs[.underlineStyle] = has ? nil : NSUnderlineStyle.single.rawValue
        case .strikethrough:
            let has = (attrs[.strikethroughStyle] as? Int ?? 0) != 0
            attrs[.strikethroughStyle] = has ? nil : NSUnderlineStyle.single.rawValue
        case .bulletList, .heading:
            break
        }
        tv.typingAttributes = attrs
    }

    // Toggle a disc bullet list on the paragraphs touched by the current selection.
    private func applyBulletList(textView tv: NSTextView, storage: NSTextStorage) {
        let sel = tv.selectedRange()
        let str = storage.string as NSString
        let paraRange = str.paragraphRange(for: sel)

        var hasList = false
        storage.enumerateAttribute(.paragraphStyle, in: paraRange) { value, _, stop in
            if let style = value as? NSParagraphStyle, !style.textLists.isEmpty {
                hasList = true
                stop.pointee = true
            }
        }

        guard tv.shouldChangeText(in: paraRange, replacementString: nil) else { return }
        storage.beginEditing()
        if hasList {
            storage.addAttribute(.paragraphStyle, value: NSParagraphStyle.default, range: paraRange)
        } else {
            let list = NSTextList(markerFormat: .disc, options: 0)
            let ps = NSMutableParagraphStyle()
            ps.textLists = [list]
            ps.firstLineHeadIndent = 0
            ps.headIndent = 22
            storage.addAttribute(.paragraphStyle, value: ps, range: paraRange)
        }
        storage.endEditing()
        tv.didChangeText()
    }

    // Change the font size (and weight) of paragraphs touched by the current selection.
    // level 0 = normal body, 1 = H1 (26 pt bold), 2 = H2 (20 pt bold), 3 = H3 (17 pt semibold).
    private func applyHeading(level: Int, textView tv: NSTextView, storage: NSTextStorage) {
        let sel = tv.selectedRange()
        let str = storage.string as NSString
        let paraRange = str.paragraphRange(for: sel)

        let makeBold: Bool
        switch level {
        case 1, 2, 3: makeBold = true
        default: makeBold = false
        }
        let baseFont = HTMLMapper.font(forHeadingLevel: level)

        guard tv.shouldChangeText(in: paraRange, replacementString: nil) else { return }
        storage.beginEditing()
        storage.enumerateAttribute(.font, in: paraRange) { value, subrange, _ in
            let src = value as? NSFont ?? HTMLMapper.bodyFont
            var traits = src.fontDescriptor.symbolicTraits
            if makeBold { traits.insert(.bold) } else { traits.remove(.bold) }
            let font = PlatformTypography.applying(traits, to: baseFont)
            storage.addAttribute(.font, value: font, range: subrange)
        }
        if level > 0 {
            storage.addAttribute(.notejotHeadingLevel, value: level, range: paraRange)
        } else {
            storage.removeAttribute(.notejotHeadingLevel, range: paraRange)
        }
        storage.endEditing()
        tv.didChangeText()
    }
}

struct EditorTextView: NSViewRepresentable {
    @Binding var text: NSAttributedString
    let formatter: EditorFormattingController

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSTextView.scrollableTextView()
        guard let textView = scroll.documentView as? NSTextView else { return scroll }

        textView.delegate = context.coordinator
        textView.textColor = .labelColor
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.font = HTMLMapper.bodyFont
        textView.textContainerInset = NSSize(width: 0, height: 12)
        textView.drawsBackground = false
        scroll.drawsBackground = false

        textView.textStorage?.setAttributedString(text)
        textView.textStorage?.addAttribute(
            .foregroundColor,
            value: NSColor.labelColor,
            range: NSRange(location: 0, length: textView.string.utf16.count)
        )
        formatter.textView = textView
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let textView = scroll.documentView as? NSTextView else { return }
        formatter.textView = textView

        // Do NOT replace the contents while the editor has focus. Unsaved text
        // lives between keystroke and debounced save, and overwriting it loses
        // whatever the user was mid-sentence on. The web build hit this.
        guard textView.window?.firstResponder !== textView else { return }
        guard textView.attributedString() != text else { return }
        textView.textStorage?.setAttributedString(text)
        textView.textStorage?.addAttribute(
            .foregroundColor,
            value: NSColor.labelColor,
            range: NSRange(location: 0, length: textView.string.utf16.count)
        )
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        private let parent: EditorTextView
        init(_ parent: EditorTextView) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.attributedString()
        }
    }
}
#elseif canImport(UIKit)
import NotejotCore
import UIKit

@MainActor
final class EditorFormattingController {
    fileprivate weak var textView: UITextView?

    enum Style { case bold, italic, underline, strikethrough, bulletList, heading(Int) }

    func apply(_ style: Style) {
        guard let textView else { return }
        let storage = textView.textStorage

        switch style {
        case .bulletList:
            applyBulletList(textView: textView, storage: storage)
            return
        case .heading(let level):
            applyHeading(level: level, textView: textView, storage: storage)
            return
        default:
            break
        }

        let range = textView.selectedRange
        guard range.length > 0 else {
            applyToTypingAttributes(style, textView: textView)
            return
        }

        guard textView.delegate?.textView?(
            textView,
            shouldChangeTextIn: range,
            replacementText: ""
        ) ?? true else { return }

        storage.beginEditing()
        switch style {
        case .bold:
            storage.enumerateAttribute(.font, in: range) { value, subrange, _ in
                let font = value as? UIFont ?? HTMLMapper.bodyFont
                storage.addAttribute(.font, value: EditorBoldStyler.toggled(font), range: subrange)
            }
        case .italic:
            storage.enumerateAttribute(.font, in: range) { value, subrange, _ in
                let font = value as? UIFont ?? HTMLMapper.bodyFont
                storage.addAttribute(.font, value: EditorBoldStyler.toggledItalic(font), range: subrange)
            }
        case .underline:
            toggleBinaryAttribute(.underlineStyle, in: range, storage: storage)
        case .strikethrough:
            toggleBinaryAttribute(.strikethroughStyle, in: range, storage: storage)
        case .bulletList, .heading:
            break
        }
        storage.endEditing()
        textView.delegate?.textViewDidChange?(textView)
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
        var attributes = textView.typingAttributes
        switch style {
        case .bold:
            let font = attributes[.font] as? UIFont ?? HTMLMapper.bodyFont
            attributes[.font] = EditorBoldStyler.toggled(font)
        case .italic:
            let font = attributes[.font] as? UIFont ?? HTMLMapper.bodyFont
            attributes[.font] = EditorBoldStyler.toggledItalic(font)
        case .underline:
            let isSet = (attributes[.underlineStyle] as? Int ?? 0) != 0
            attributes[.underlineStyle] = isSet ? nil : NSUnderlineStyle.single.rawValue
        case .strikethrough:
            let isSet = (attributes[.strikethroughStyle] as? Int ?? 0) != 0
            attributes[.strikethroughStyle] = isSet ? nil : NSUnderlineStyle.single.rawValue
        case .bulletList, .heading:
            break
        }
        textView.typingAttributes = attributes
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
        let shouldBeBold = level > 0
        let baseFont = HTMLMapper.font(forHeadingLevel: level)

        storage.beginEditing()
        storage.enumerateAttribute(.font, in: paragraphRange) { value, subrange, _ in
            let source = value as? UIFont ?? HTMLMapper.bodyFont
            var traits = source.fontDescriptor.symbolicTraits
            if shouldBeBold {
                traits.insert(PlatformTypography.boldTrait)
            } else {
                traits.remove(PlatformTypography.boldTrait)
            }
            let font = PlatformTypography.applying(traits, to: baseFont)
            storage.addAttribute(.font, value: font, range: subrange)
        }
        if level > 0 {
            storage.addAttribute(.notejotHeadingLevel, value: level, range: paragraphRange)
        } else {
            storage.removeAttribute(.notejotHeadingLevel, range: paragraphRange)
        }
        storage.endEditing()
        textView.delegate?.textViewDidChange?(textView)
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
