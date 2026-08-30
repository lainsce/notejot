import NotejotCore
import SwiftUI

struct AvailableTagRow: View {
    let facet: TagFacet
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: NotejotColors.gridUnit) {
                TagMarker(tag: facet.tag, size: 8)
                    .accessibilityHidden(true)

                Text(facet.name)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(facet.count, format: .number)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)

                Image(systemName: "plus")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, NotejotColors.gridUnit * 2)
            .frame(minHeight: NotejotLayoutMetrics.smallInteractiveControlSize)
            .contentShape(.rect(cornerRadius: NotejotColors.controlRadius))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add \(facet.name) tag")
        .accessibilityValue(Text("Used by ^[\(facet.count) note](inflect: true)"))
    }
}
