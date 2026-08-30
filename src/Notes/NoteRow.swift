import SwiftUI
import NotejotCore

struct NoteRow: View {
    let note: Note

    @State private var previewText = ""

    var body: some View {
        HStack(alignment: .top, spacing: SidebarMetrics.horizontalSpacing) {
            VStack(alignment: .leading, spacing: NotejotColors.gridUnit) {
                HStack(alignment: .top, spacing: 4) {
                    Text(formattedNoteDate(note.updatedAt))
                        .font(NotejotTypography.caption)
                        .monospacedDigit()
                        .foregroundStyle(.tertiary)

                    if !note.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(note.tags.prefix(8)) { tag in
                                TagMarker(tag: tag, size: 8)
                            }
                        }
                        .padding(.top, NotejotColors.gridUnit)
                    }
                }

                HStack(spacing: 4) {
                    Text(note.title.isEmpty ? "Untitled" : note.title)
                        .font(NotejotTypography.contentBlockTitle)
                        .lineLimit(1)
                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Pinned")
                    }
                }

                Text(previewText)
                    .font(NotejotTypography.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if let source = note.images.first {
                Spacer()
                DataURLImage(
                    source: source,
                    accessibilityLabel: "Attachment preview for \(displayTitle)"
                )
                .aspectRatio(contentMode: .fill)
                .frame(width: 64, height: 64)
                .clipShape(.rect(cornerRadius: NotejotColors.controlRadius))
            }
        }
        .padding(.vertical, 4)
        .task(id: note.content) {
            previewText = HTMLMapper.plainTextPreview(fromHTML: note.content)
        }
    }

    private var displayTitle: String {
        note.title.isEmpty ? String(localized: "Untitled") : note.title
    }
}
