import NotejotCore
import SwiftUI

struct ImageFlyoutCell: View {
    let note: Note
    let source: String
    let index: Int
    let onRemoveLastImage: () -> Void

    @Environment(NoteStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .topTrailing) {
            DataURLImage(source: source, accessibilityLabel: "Attached image \(index + 1)")
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: NotejotColors.industrialSmallRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: NotejotColors.industrialSmallRadius)
                        .strokeBorder(NotejotColors.industrialRule(for: colorScheme), lineWidth: 1)
                }
                .background(
                    NotejotColors.surface(for: colorScheme),
                    in: RoundedRectangle(cornerRadius: NotejotColors.industrialSmallRadius)
                )

            Button(
                "Remove image \(index + 1)",
                systemImage: "xmark.circle.fill",
                role: .destructive,
                action: removeImage
            )
                .labelStyle(.iconOnly)
                .imageScale(.large)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(NotejotColors.destructive)
                .buttonStyle(.plain)
                .frame(
                    width: NotejotLayoutMetrics.minimumInteractiveControlSize,
                    height: NotejotLayoutMetrics.minimumInteractiveControlSize
                )
        }
    }

    private func removeImage() {
        var images = note.images
        guard images.indices.contains(index) else { return }
        images.remove(at: index)
        store.updateImages(id: note.id, images: images)
        if images.isEmpty { onRemoveLastImage() }
    }
}
