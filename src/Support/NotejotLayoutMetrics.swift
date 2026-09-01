import CoreGraphics

enum NotejotLayoutMetrics {
    static let minimumWindowWidth: CGFloat = 390
    static let compactTitleHorizontalInset: CGFloat = 24
    static let compactEditorHorizontalInset: CGFloat = 16
    static let compactToolbarControlSize: CGFloat = 38
    static let compactToolbarSegmentSize: CGFloat = 38
    static let toolbarIconSize: CGFloat = 22
    static let compactToolbarControlInset: CGFloat = 0
    static let fieldHeight: CGFloat = NotejotColors.fieldHeight
#if os(iOS)
    static let minimumInteractiveControlSize: CGFloat = 44
    static let smallInteractiveControlSize: CGFloat = 44
    static let tagRemovalControlSize: CGFloat = 44
    static let sidebarSearchHeight: CGFloat = fieldHeight
    static let popoverWidth: CGFloat = 320
    static let imageFlyoutMinimumWidth: CGFloat = 0
    static let imageFlyoutMinimumHeight: CGFloat = 0
#else
    static let minimumInteractiveControlSize: CGFloat = 38
    static let smallInteractiveControlSize: CGFloat = 38
    static let tagRemovalControlSize: CGFloat = 24
    static let sidebarSearchHeight: CGFloat = fieldHeight
    static let popoverWidth: CGFloat = 248
    static let imageFlyoutMinimumWidth: CGFloat = 480
    static let imageFlyoutMinimumHeight: CGFloat = 360
#endif
}
