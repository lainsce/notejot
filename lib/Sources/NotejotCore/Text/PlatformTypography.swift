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

    public static var monospacedFont: NotejotFont {
#if canImport(AppKit)
        .monospacedSystemFont(ofSize: 14, weight: .regular)
#else
        UIFontMetrics(forTextStyle: .body).scaledFont(
            for: .monospacedSystemFont(ofSize: 14, weight: .regular)
        )
#endif
    }

    public static func headingFont(level: Int) -> NotejotFont {
        let size: CGFloat
#if canImport(AppKit)
        switch level {
        case 1: size = 28
        case 2: size = 24
        case 3: size = 18
        default: return bodyFont
        }
        return geistFont(size: size, weight: .semibold)
#else
        let textStyle: UIFont.TextStyle
        switch level {
        case 1: size = 28; textStyle = .title1
        case 2: size = 24; textStyle = .title2
        case 3: size = 18; textStyle = .headline
        default: return bodyFont
        }
        return dynamicGeistFont(size: size, textStyle: textStyle, weight: .semibold)
#endif
    }

#if canImport(AppKit)
    private static func geistFont(size: CGFloat, weight: NSFont.Weight) -> NSFont {
        let name = weight == .semibold ? "Geist-SemiBold" : "Geist-Regular"
        return NSFont(name: name, size: size)
            ?? NSFont.systemFont(ofSize: size, weight: weight)
    }
#else
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
