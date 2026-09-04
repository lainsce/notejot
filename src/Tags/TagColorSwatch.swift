import SwiftUI

struct TagColorSwatch: View {
    let hex: String
    let name: LocalizedStringResource
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            RoundedRectangle(
                cornerRadius: NotejotColors.industrialSmallRadius,
                style: .continuous
            )
                .fill(NotejotColors.itemSurface)
                .overlay(alignment: .bottom) {
                    RoundedRectangle(
                        cornerRadius: NotejotColors.industrialSmallRadius,
                        style: .continuous
                    )
                    .fill(Color(hex: hex) ?? NotejotColors.accent)
                    .frame(height: 4)
                        .padding(NotejotColors.gridUnit)
                }
                .overlay {
                    if isSelected {
                        RoundedRectangle(
                            cornerRadius: NotejotColors.industrialSmallRadius,
                            style: .continuous
                        )
                        .strokeBorder(NotejotColors.accent, lineWidth: 2)
                    }
                }
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.primary)
                            .accessibilityHidden(true)
                    }
                }
        }
        .buttonStyle(.plain)
        .frame(
            width: NotejotLayoutMetrics.smallInteractiveControlSize,
            height: NotejotLayoutMetrics.smallInteractiveControlSize
        )
        .contentShape(.rect(cornerRadius: NotejotColors.industrialSmallRadius))
        .animation(NotejotMotion.controlAnimation(reduceMotion: reduceMotion), value: isSelected)
        .accessibilityLabel(Text(name))
        .accessibilityValue(
            Text(isSelected ? "Selected" : "Not Selected")
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
