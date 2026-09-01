import CoreText
import Foundation

enum NotejotFontRegistration {
    private static let fontNames = [
        "Geist-Regular",
        "Geist-Medium",
        "Geist-SemiBold",
        "Geist-Bold",
        "Geist-Black",
        "Lekton-Regular",
        "Lekton-Bold",
        "Lekton-Italic",
        "OldStandardTT-Regular",
        "OldStandardTT-Italic",
        "OldStandardTT-Bold"
    ]

    static func register() {
        for fontName in fontNames {
            guard let url = Bundle.main.url(forResource: fontName, withExtension: "ttf", subdirectory: "Fonts") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
