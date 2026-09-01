#if canImport(AppKit)
import AppKit

public typealias NotejotFont = NSFont
public typealias NotejotFontTraits = NSFontDescriptor.SymbolicTraits
#elseif canImport(UIKit)
import UIKit

public typealias NotejotFont = UIFont
public typealias NotejotFontTraits = UIFontDescriptor.SymbolicTraits
#endif

public enum PlatformTypography {
    public static var bodyFont: NotejotFont {
#if canImport(AppKit)
        geistFont(size: 14, weight: .regular)
#else
        dynamicGeistFont(size: 14, textStyle: .body, weight: .regular)
#endif
    }

    /// Technical/code text uses the bundled Lekton family when available.
    /// Keep the legacy property name as an API-compatible alias for HTML
    /// mapping callers.
    public static var technicalFont: NotejotFont {
#if canImport(AppKit)
        lektonFont(size: 14, weight: .regular)
#else
        dynamicLektonFont(size: 14, textStyle: .body, weight: .regular)
#endif
    }

    public static var monospacedFont: NotejotFont { technicalFont }

    public static func headingFont(level: Int) -> NotejotFont {
#if canImport(AppKit)
        guard let size = headingSize(level) else { return bodyFont }
        return geistFont(size: size, weight: .semibold)
#else
        guard let heading = headingStyle(level) else { return bodyFont }
        let size = heading.size
        let textStyle = heading.style
        return dynamicGeistFont(size: size, textStyle: textStyle, weight: .semibold)
#endif
    }

    private static func headingSize(_ level: Int) -> CGFloat? {
        [1: CGFloat(28), 2: 24, 3: 18][level]
    }

#if canImport(UIKit)
    private static func headingStyle(_ level: Int) -> (size: CGFloat, style: UIFont.TextStyle)? {
        [1: (28, UIFont.TextStyle.title1), 2: (24, .title2), 3: (18, .headline)][level]
    }
#endif

#if canImport(AppKit)
    private static func lektonFont(size: CGFloat, weight: NSFont.Weight) -> NSFont {
        NSFont(name: weight == .bold ? "Lekton-Bold" : "Lekton-Regular", size: size)
            ?? NSFont.monospacedSystemFont(ofSize: size, weight: weight)
    }

    private static func geistFont(size: CGFloat, weight: NSFont.Weight) -> NSFont {
        let name = weight == .semibold ? "Geist-SemiBold" : "Geist-Regular"
        return NSFont(name: name, size: size)
            ?? NSFont.systemFont(ofSize: size, weight: weight)
    }
#else
    private static func dynamicLektonFont(
        size: CGFloat,
        textStyle: UIFont.TextStyle,
        weight: UIFont.Weight
    ) -> UIFont {
        let name = weight == .bold ? "Lekton-Bold" : "Lekton-Regular"
        let font = UIFont(name: name, size: size)
            ?? UIFont.monospacedSystemFont(ofSize: size, weight: weight)
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: font)
    }

    private static func dynamicGeistFont(
        size: CGFloat,
        textStyle: UIFont.TextStyle,
        weight: UIFont.Weight
    ) -> UIFont {
        let name = weight == .semibold ? "Geist-SemiBold" : "Geist-Regular"
        let font = UIFont(name: name, size: size)
            ?? UIFont.systemFont(ofSize: size, weight: weight)
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: font)
    }
#endif

    public static var boldTrait: NotejotFontTraits {
#if canImport(AppKit)
        .bold
#elseif canImport(UIKit)
        .traitBold
#endif
    }

    public static var italicTrait: NotejotFontTraits {
#if canImport(AppKit)
        .italic
#elseif canImport(UIKit)
        .traitItalic
#endif
    }

    public static func applying(
        _ traits: NotejotFontTraits,
        to font: NotejotFont
    ) -> NotejotFont {
#if canImport(AppKit)
        NotejotFont(
            descriptor: font.fontDescriptor.withSymbolicTraits(traits),
            size: font.pointSize
        ) ?? font
#elseif canImport(UIKit)
        guard let descriptor = font.fontDescriptor.withSymbolicTraits(traits) else {
            return font
        }
        return NotejotFont(descriptor: descriptor, size: font.pointSize)
#endif
    }
}
