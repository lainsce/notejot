import SwiftUI

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

/// Geist-first typography for the Metro hierarchy, with Old Standard TT used
/// for view titles. Missing glyphs remain eligible for the platform's
/// serif/Mincho fallback while preserving the Dynamic Type relationship.
enum NotejotTypography {
    /// The shared Nuul text scale. Roles are anchored to Dynamic Type styles so
    /// accessibility settings grow the hierarchy without introducing ad-hoc
    /// sizes in individual views.
    enum Role: CaseIterable {
        case bigDisplay, display, viewTitle, viewSubtitle
        case contentBlockTitle, contentBlockSubtitle, body, caption, micro

        var size: CGFloat {
            switch self {
            case .bigDisplay: return 42
            case .display: return 32
            case .viewTitle: return 28
            case .viewSubtitle: return 24
            case .contentBlockTitle: return 18
            case .contentBlockSubtitle: return 16
            case .body: return 14
            case .caption: return 12
            case .micro: return 9
            }
        }

        var relativeTo: Font.TextStyle {
            switch self {
            case .bigDisplay, .display: return .largeTitle
            case .viewTitle: return .title
            case .viewSubtitle: return .title2
            case .contentBlockTitle: return .headline
            case .contentBlockSubtitle: return .subheadline
            case .body: return .body
            case .caption: return .caption
            case .micro: return .caption2
            }
        }
    }

    static func font(_ role: Role) -> Font {
        if role == .viewTitle {
            return viewTitleFont(role)
        }
        return Font.custom(fontName(for: role), size: role.size, relativeTo: role.relativeTo)
    }

    static let bigDisplay = font(.bigDisplay)
    static let display = font(.display)
    static let viewTitle = font(.viewTitle)
    static let viewSubtitle = font(.viewSubtitle)
    static let contentBlockTitle = font(.contentBlockTitle)
    static let contentBlockSubtitle = font(.contentBlockSubtitle)
    static let body = font(.body)
    static let caption = font(.caption)
    static let micro = font(.micro)

    /// Compatibility funnel for existing call sites. Any legacy size is
    /// quantized to one of the canonical roles.
    static func ui(
        _ size: CGFloat,
        weight _: Font.Weight = .regular,
        relativeTo _: Font.TextStyle = .body
    ) -> Font {
        font(role(for: size))
    }

    private static func role(for size: CGFloat) -> Role {
        switch size {
        case 38...: return .bigDisplay
        case 30..<38: return .display
        case 26..<30: return .viewTitle
        case 21..<26: return .viewSubtitle
        case 17..<21: return .contentBlockTitle
        case 15..<17: return .contentBlockSubtitle
        case 13..<15: return .body
        case 11..<13: return .caption
        default: return .micro
        }
    }

    private static func fontName(for role: Role) -> String {
        switch role {
        case .contentBlockTitle, .caption: return "Geist-SemiBold"
        default: return "Geist-Regular"
        }
    }

    private static func viewTitleFont(_ role: Role) -> Font {
#if os(macOS)
        guard NSFont(name: "OldStandardTT-Regular", size: role.size) != nil else {
            return platformMinchoFont(role)
        }
#elseif os(iOS)
        guard UIFont(name: "OldStandardTT-Regular", size: role.size) != nil else {
            return platformMinchoFont(role)
        }
#endif
        return .custom("OldStandardTT-Regular", size: role.size, relativeTo: role.relativeTo)
    }

    private static func platformMinchoFont(_ role: Role) -> Font {
        let families = ["Hiragino Mincho ProN", "Hiragino Mincho Pro", "YuMincho", "Songti SC"]
#if os(macOS)
        for family in families where NSFont(name: family, size: role.size) != nil {
            return .custom(family, size: role.size, relativeTo: role.relativeTo)
        }
#elseif os(iOS)
        for family in families where UIFont(name: family, size: role.size) != nil {
            return .custom(family, size: role.size, relativeTo: role.relativeTo)
        }
#endif
        return .system(role.relativeTo, design: .serif)
    }
}
