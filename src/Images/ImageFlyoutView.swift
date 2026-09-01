import NotejotCore
import SwiftUI

struct ImageFlyoutView: View {
    let note: Note

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if note.images.count == 1 {
                    Text("1 image")
                        .font(NotejotTypography.technicalFont(.contentBlockSubtitle))
                } else {
                    Text("\(note.images.count) of 4 images")
                        .font(NotejotTypography.technicalFont(.contentBlockSubtitle))
                }
                Spacer()
                Button("Close", systemImage: "xmark.circle.fill") {
                    dismiss()
                }
                .labelStyle(.iconOnly)
                .imageScale(.large)
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)
                .frame(
                    width: NotejotLayoutMetrics.minimumInteractiveControlSize,
                    height: NotejotLayoutMetrics.minimumInteractiveControlSize
                )
            }
            .padding()

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 12) {
                    ForEach(note.images.enumerated(), id: \.offset) { index, source in
                        ImageFlyoutCell(note: note, source: source, index: index) {
                            if note.images.count == 1 { dismiss() }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(
            minWidth: NotejotLayoutMetrics.imageFlyoutMinimumWidth,
            minHeight: NotejotLayoutMetrics.imageFlyoutMinimumHeight
        )
        .background(NotejotColors.windowBackground(for: colorScheme))
    }
}
