import NotejotCore
import SwiftUI

struct CompactEditorFormattingBar: View {
    let formatter: EditorFormattingController
    let canAddImage: Bool
    let addImage: () -> Void
    @Binding var isShowingTagPopover: Bool
    let note: Note

    var body: some View {
        HStack(spacing: SidebarMetrics.horizontalSpacing) {
            HStack(spacing: NotejotColors.gridUnit) {
                formatButton("Bold", systemImage: "bold", style: .bold, help: "Bold (⌘B)")
                formatButton("Italic", systemImage: "italic", style: .italic, help: "Italic (⌘I)")

                Menu {
                    Button("Underline", systemImage: "underline", action: applyUnderline)
                    Button("Strikethrough", systemImage: "strikethrough", action: applyStrikethrough)
                    Button("Bulleted List", systemImage: "list.bullet", action: applyBulletedList)
                    Divider()
                    Menu("Heading Style", systemImage: "textformat.size") {
                        Button("Normal Text", action: applyNormalText)
                        Button("Heading 1", action: applyHeadingOne)
                        Button("Heading 2", action: applyHeadingTwo)
                        Button("Heading 3", action: applyHeadingThree)
                    }
                } label: {
                    HStack(spacing: NotejotColors.gridUnit) {
                        NULIcon(systemImage: "textformat")
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.primary)
                }
                .accessibilityLabel("More Formatting")
                .menuStyle(.button)
                .buttonStyle(.borderless)
                .menuIndicator(.hidden)
                .tint(.primary)
                .notejotIOSControlEmphasis()
                .frame(
                    width: NotejotLayoutMetrics.compactToolbarSegmentSize,
                    height: NotejotLayoutMetrics.compactToolbarSegmentSize
                )
                .notejotToolbarHitTarget()
                .contentShape(.rect)
                .help("More Formatting")
            }
            .padding(NotejotLayoutMetrics.compactToolbarControlInset)
            .nulToolbarSurface(
                RoundedRectangle(
                    cornerRadius: NotejotColors.industrialSmallRadius,
                    style: .continuous
                )
            )
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Text formatting")

            Menu {
                Button("Add Image", systemImage: "photo.badge.plus", action: addImage)
                    .disabled(!canAddImage)
                Button("Add Tag", systemImage: "tag", action: showTagPopover)
            } label: {
                HStack(spacing: NotejotColors.gridUnit) {
                    NULIcon(systemImage: "plus")
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
            }
            .accessibilityLabel("Insert")
            .menuStyle(.button)
            .buttonStyle(.borderless)
            .menuIndicator(.hidden)
            .notejotIOSControlEmphasis()
            .frame(
                width: NotejotLayoutMetrics.compactToolbarControlSize,
                height: NotejotLayoutMetrics.compactToolbarControlSize
            )
            .notejotToolbarHitTarget()
            .contentShape(.rect)
            .nulToolbarSurface(
                RoundedRectangle(
                    cornerRadius: NotejotColors.industrialSmallRadius,
                    style: .continuous
                )
            )
            .help("Insert")
            .popover(isPresented: $isShowingTagPopover, arrowEdge: .bottom) {
                TagPopoverView(note: note)
                    .presentationBackground(NotejotColors.itemSurface)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Editor controls")
    }

    private func formatButton(
        _ title: String,
        systemImage: String,
        style: EditorFormattingController.Style,
        help: String
    ) -> some View {
        Button(action: {
            formatter.apply(style)
        }) {
            NULIcon(systemImage: systemImage)
        }
        .accessibilityLabel(title)
        .buttonStyle(.plain)
        .notejotIOSControlEmphasis()
        .frame(
            width: NotejotLayoutMetrics.compactToolbarSegmentSize,
            height: NotejotLayoutMetrics.compactToolbarSegmentSize
        )
        .notejotToolbarHitTarget()
        .contentShape(.rect)
        .help(help)
    }

    private func applyUnderline() {
        formatter.apply(.underline)
    }

    private func applyStrikethrough() {
        formatter.apply(.strikethrough)
    }

    private func applyBulletedList() {
        formatter.apply(.bulletList)
    }

    private func applyNormalText() {
        formatter.apply(.heading(0))
    }

    private func applyHeadingOne() {
        formatter.apply(.heading(1))
    }

    private func applyHeadingTwo() {
        formatter.apply(.heading(2))
    }

    private func applyHeadingThree() {
        formatter.apply(.heading(3))
    }

    private func showTagPopover() {
        isShowingTagPopover = true
    }
}
