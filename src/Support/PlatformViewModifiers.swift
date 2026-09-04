import SwiftUI

extension View {
    @ViewBuilder
    func notejotToolbarBackgroundHidden() -> some View {
#if os(macOS)
        toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
#else
        self
#endif
    }

    @ViewBuilder
    func notejotSidebarToggleRemoved() -> some View {
#if os(macOS)
        toolbar(removing: .sidebarToggle)
#else
        self
#endif
    }

    @ViewBuilder
    func notejotIOSControlEmphasis() -> some View {
#if os(iOS)
        imageScale(.large)
#else
        self
#endif
    }

    /// Keeps custom toolbar visuals at 38 points while preserving iOS's
    /// minimum interactive target around them.
    @ViewBuilder
    func notejotToolbarHitTarget() -> some View {
#if os(iOS)
        frame(
            width: NotejotLayoutMetrics.minimumInteractiveControlSize,
            height: NotejotLayoutMetrics.minimumInteractiveControlSize
        )
        .contentShape(.rect(cornerRadius: NotejotColors.controlRadius))
#else
        contentShape(.rect(cornerRadius: NotejotColors.controlRadius))
#endif
    }
}
