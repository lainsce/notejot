import SwiftUI

/// The editor canvas is intentionally quiet: a single paper tone, one rule,
/// and a hairline edge. Tag color belongs to metadata controls, not the page
/// background, so notes remain readable and the accent stays meaningful.
struct QuantumPaperBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let paperShape = RoundedRectangle(
            cornerRadius: NotejotColors.industrialRadius,
            style: .continuous
        )

        NotejotColors.paperBackground(for: colorScheme)
        .clipShape(paperShape)
    }
}
