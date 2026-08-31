import SwiftUI

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

enum NotejotColors {
    // Four-point geometry is shared by fields, rows, and compact controls.
    static let gridUnit: CGFloat = 4
    static let formRowSpacing: CGFloat = gridUnit * 4
    static let formLabelWidth: CGFloat = gridUnit * 32
    static let fieldHorizontalPadding: CGFloat = gridUnit * 3
    static let fieldHeight: CGFloat = gridUnit * 9
    static let controlRadius: CGFloat = gridUnit
    static let largeSurfaceRadius: CGFloat = gridUnit * 3

    /// The app accent, reserved for selection and primary creation actions.
    /// AccentColor intentionally keeps Notejot's signature #F6D32D in light
    /// mode (with the deeper #BA9E00 dark companion). User-authored tag
    /// colors remain independent and are rendered as-is.
    static let accent = Color("AccentColor")
    static let destructive = Color.red

    /// Large scene surfaces use the restrained industrial gray.
    static func windowBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0, green: 0, blue: 0)
            : Color(red: 242 / 255, green: 242 / 255, blue: 242 / 255)
    }

    /// Sidebar columns are opaque and slightly darker than the document
    /// workspace. Keeping this separate from the window surface prevents the
    /// system's translucent sidebar material from leaking through.
    static func sidebarBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 42 / 255, green: 42 / 255, blue: 42 / 255)
            : Color(red: 228 / 255, green: 228 / 255, blue: 228 / 255)
    }

    static func sidebarDivider(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.12)
            : Color.black.opacity(0.12)
    }

    /// Item surfaces are deliberately a little brighter than the workspace.
    /// Keep these values explicit rather than inheriting a platform window
    /// background, so the industrial palette is stable across hosts.
    static func surface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 17 / 255, green: 17 / 255, blue: 17 / 255)
            : Color(red: 253 / 255, green: 253 / 255, blue: 253 / 255)
    }

    /// Appearance-aware surface for call sites that do not already receive a
    /// color-scheme environment value.
    static var itemSurface: Color {
#if os(macOS)
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? NSColor(srgbRed: 17 / 255, green: 17 / 255, blue: 17 / 255, alpha: 1)
                : NSColor(srgbRed: 253 / 255, green: 253 / 255, blue: 253 / 255, alpha: 1)
        })
#elseif os(iOS)
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 17 / 255, green: 17 / 255, blue: 17 / 255, alpha: 1)
                : UIColor(red: 253 / 255, green: 253 / 255, blue: 253 / 255, alpha: 1)
        })
#else
        Color(red: 253 / 255, green: 253 / 255, blue: 253 / 255)
#endif
    }

    static var contentSurface: Color {
        itemSurface
    }
    static let selectedGridCardSurface = accent.opacity(0.12)

    static let industrialRadius: CGFloat = largeSurfaceRadius
    static let industrialSmallRadius: CGFloat = controlRadius
    static func industrialRule(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.16)
            : Color.black.opacity(0.12)
    }

    static func industrialQuietRule(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.06)
    }

    // Shared sidebar row states. The selected tint is deliberately faint so
    // the row remains legible while still using the app accent as the state
    // signal, like the native Notejot destination rows.
    static let sidebarSelectedFillOpacity: Double = 0.14
    static let sidebarPressedFillOpacity: Double = 0.22
    static let sidebarHoverFillOpacity: Double = 0.06
    static let sidebarSelectedBorderOpacity: Double = 0.72

    static func panelBackground(for colorScheme: ColorScheme) -> Color {
        windowBackground(for: colorScheme)
    }

    static func elevatedSurface(for colorScheme: ColorScheme) -> Color {
        surface(for: colorScheme)
    }

    static func paperBackground(for colorScheme: ColorScheme) -> Color {
        surface(for: colorScheme)
    }

    static var gridCardSurface: Color {
        contentSurface
    }

    static var selectedSurface: Color {
        Color.primary.opacity(0.08)
    }
}

/// A deliberately flat, geometric surface used for cards, controls, and
/// toolbars. It keeps internal controls on the same layer rather than adding
/// nested glass effects.
struct NotejotIndustrialSurface<S: InsettableShape>: ViewModifier {
    let shape: S
    let selected: Bool

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(NotejotColors.surface(for: colorScheme), in: shape)
            .overlay {
                if selected {
                    shape.strokeBorder(NotejotColors.accent, lineWidth: 1.5)
                }
            }
    }
}

extension View {
    func notejotIndustrialSurface<S: InsettableShape>(
        _ shape: S,
        selected: Bool = false
    ) -> some View {
        modifier(NotejotIndustrialSurface(shape: shape, selected: selected))
    }
}
