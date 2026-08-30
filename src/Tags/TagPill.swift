import NotejotCore
import SwiftUI

struct TagPill: View {
    let tag: Tag
    let onRemove: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: NotejotColors.gridUnit) {
            TagMarker(tag: tag, size: 8)
                .accessibilityHidden(true)

            Text(tag.name)
                .font(NotejotTypography.body)
                .accessibilityLabel("Tag: \(tag.name)")

            Button(
                "Remove \(tag.name) tag",
                systemImage: "xmark",
                role: .destructive,
                action: onRemove
            )
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .frame(
                    width: NotejotLayoutMetrics.tagRemovalControlSize,
                    height: NotejotLayoutMetrics.tagRemovalControlSize
                )
                .contentShape(.circle)
        }
        .foregroundStyle(.primary)
        .frame(minHeight: NotejotLayoutMetrics.smallInteractiveControlSize)
        .padding(.leading, 8)
        .padding(.trailing, NotejotColors.gridUnit)
        .background(
            NotejotColors.itemSurface,
            in: RoundedRectangle(
                cornerRadius: NotejotColors.industrialSmallRadius,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: NotejotColors.industrialSmallRadius,
                style: .continuous
            )
            .strokeBorder(NotejotColors.industrialRule(for: colorScheme), lineWidth: 2)
        }
        .accessibilityElement(children: .contain)
    }
}
