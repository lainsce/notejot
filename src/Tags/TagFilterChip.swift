import NotejotCore
import SwiftUI

struct TagFilterChip: View {
    let tag: Tag?
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var title: String { tag?.name ?? "All" }

    private var surface: Color {
        isSelected
            ? NotejotColors.accent
            : NotejotColors.itemSurface
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: SidebarMetrics.horizontalSpacing) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .accessibilityHidden(true)
                }

                if let tag {
                    TagMarker(tag: tag, size: 8)
                        .accessibilityHidden(true)
                }

                if tag == nil {
                    Text("All")
                        .lineLimit(1)
                } else {
                    Text(title)
                        .lineLimit(1)
                }

                Text(count, format: .number)
                    .font(NotejotTypography.technicalFont(.body))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .font(NotejotTypography.body)
            .padding(.horizontal, NotejotColors.fieldHorizontalPadding)
            .frame(minHeight: NotejotLayoutMetrics.smallInteractiveControlSize)
            .contentShape(.rect(cornerRadius: NotejotColors.industrialSmallRadius))
        }
        .buttonStyle(.plain)
        .background(
            surface,
            in: RoundedRectangle(
                cornerRadius: NotejotColors.industrialSmallRadius,
                style: .continuous
            )
        )
        .overlay {
            if isSelected {
                RoundedRectangle(
                    cornerRadius: NotejotColors.industrialSmallRadius,
                    style: .continuous
                )
                .strokeBorder(NotejotColors.accent, lineWidth: 2)
            }
        }
        .accessibilityLabel(accessibilityTitle)
        .accessibilityValue(Text("^[\(count) note](inflect: true)"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .help(helpText)
        .animation(NotejotMotion.controlAnimation(reduceMotion: reduceMotion), value: isSelected)
    }

    private var accessibilityTitle: Text {
        if tag == nil {
            Text("All Tags")
        } else {
            Text("Tag: \(title)")
        }
    }

    private var helpText: Text {
        if tag == nil {
            Text("Show All Notes")
        } else {
            Text("Filter by \(title)")
        }
    }
}
