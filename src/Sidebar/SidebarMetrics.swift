import CoreGraphics

enum SidebarMetrics {
    static let horizontalInset: CGFloat = 8
    static let horizontalSpacing: CGFloat = 6
    static let verticalSpacing: CGFloat = 12
    static let halfVerticalSpacing = verticalSpacing / 2
    static let gridTextOnlyExcerptLineLimit = 8
    static let gridImageExcerptLineLimit = 3

    // The packed card geometry fits at 330 points, but at that width the
    // LazyVStack columns have no flexible room around their 144-point cards.
    // Keep the visually verified 320-point sidebar fixed so its card shadows,
    // selection rings, and control spacing cannot be distorted by resizing.
    nonisolated static let width: CGFloat = 320

    // The destination picker is a separate sidebar on macOS. Keep it fixed as
    // well so dragging either split divider cannot change the navigation
    // geometry.
    nonisolated static let destinationWidth: CGFloat = 220

    // Native macOS toolbar items include a leading inset that is independent
    // from the fixed split-view columns. These reservations align the
    // distributed middle controls with the pane edges without changing the
    // pane widths themselves.
    nonisolated static let toolbarDestinationReservation: CGFloat = 117

    // Leave the detail column enough room for its formatting lane and editor
    // actions before switching to the compact navigation stack.
    nonisolated static let wideNavigationMinimumWidth: CGFloat = destinationWidth + width + 500
}
