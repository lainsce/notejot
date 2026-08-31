#if os(macOS)
import SwiftUI

struct MacSidebarToolbar: View {
    let isSearchPresented: Bool
    let toggleSearch: () -> Void
    @Binding var viewMode: SidebarViewMode
    let createButtonLabel: LocalizedStringKey
    let createButtonHelp: LocalizedStringKey
    let createItem: () -> Void
    let distributesAcrossLane: Bool

    var body: some View {
        HStack(spacing: distributesAcrossLane ? 0 : 12) {
            HStack(spacing: 0) {
                Button(action: toggleSearch) {
                    NULIcon(systemImage: "magnifyingglass")
                }
                .accessibilityLabel(isSearchPresented ? "Hide Search" : "Show Search")
                .buttonStyle(.plain)
                .frame(
                    width: NotejotLayoutMetrics.compactToolbarControlSize,
                    height: NotejotLayoutMetrics.compactToolbarControlSize
                )
                .help(isSearchPresented ? "Hide Search" : "Show Search")
            }
            .nulToolbarSurface(
                RoundedRectangle(cornerRadius: NotejotColors.industrialSmallRadius, style: .continuous)
            )
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Note list actions")
            .padding(.trailing, NotejotColors.gridUnit * 2)

            HStack(spacing: 0) {
                NULSegmentedPicker(
                    selection: $viewMode,
                    options: [.list, .grid]
                ) { mode in
                    Label(
                        mode == .list ? "List" : "Grid",
                        systemImage: mode == .list ? "list.bullet" : "square.grid.2x2"
                    )
                    .labelStyle(.iconOnly)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.primary)
                }
                .frame(width: 72, height: NotejotLayoutMetrics.compactToolbarControlSize)
                .help("View Options")
            }
            .nulToolbarSurface(
                RoundedRectangle(cornerRadius: NotejotColors.industrialSmallRadius, style: .continuous)
            )
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Note list actions")

            if distributesAcrossLane {
                Spacer(minLength: 0)
            }

            Button(action: createItem) {
                NULIcon(systemImage: "plus", foregroundColor: .black)
            }
            .accessibilityLabel(createButtonLabel)
            .buttonStyle(.plain)
            .frame(
                width: NotejotLayoutMetrics.compactToolbarControlSize,
                height: NotejotLayoutMetrics.compactToolbarControlSize
            )
            .background(
                NotejotColors.accent,
                in: RoundedRectangle(
                    cornerRadius: NotejotColors.industrialSmallRadius,
                    style: .continuous
                )
            )
            .contentShape(Rectangle())
            .help(createButtonHelp)
        }
        .padding(.horizontal, distributesAcrossLane ? NotejotColors.gridUnit * 2 : 0)
        .frame(
            // Use one width for both layout and hit testing. The previous
            // nested 320pt/262pt frames let the trailing plus render outside
            // the toolbar host's interactive bounds.
            width: distributesAcrossLane ? SidebarMetrics.width : nil,
            alignment: .leading
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Note list actions")
        .nulWindowActivityAppearance()
    }
}
#endif
