import SwiftUI

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

/// Geist-first typography for the Metro hierarchy, with Old Standard TT used
/// for view titles and Lekton used for technical data. Missing glyphs remain
/// eligible for the platform's serif/Mincho fallback while preserving the
/// Dynamic Type relationship.
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

    static func technicalFont(_ role: Role) -> Font {
        Font.custom("Lekton", size: role.size, relativeTo: role.relativeTo)
    }

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
        let roles: [(lower: CGFloat, upper: CGFloat?, role: Role)] = [
            (38, nil, .bigDisplay),
            (30, 38, .display),
            (26, 30, .viewTitle),
            (21, 26, .viewSubtitle),
            (17, 21, .contentBlockTitle),
            (15, 17, .contentBlockSubtitle),
            (13, 15, .body),
            (11, 13, .caption),
        ]
        return roles.first { contains(size, lower: $0.lower, upper: $0.upper) }?.role ?? .micro
    }

    private static func contains(_ size: CGFloat, lower: CGFloat, upper: CGFloat?) -> Bool {
        guard size >= lower else { return false }
        guard let upper else { return true }
        return size < upper
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
