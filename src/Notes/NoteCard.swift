import SwiftUI
import NotejotCore

struct NoteCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let note: Note
    let isSelected: Bool

    @State private var previewText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: NotejotColors.gridUnit * 2) {
            if let source = note.images.first {
                NoteCardAttachment(source: source, noteTitle: displayTitle)
            }

            Text(formattedNoteDate(note.updatedAt))
                .font(NotejotTypography.technicalFont(.caption))
                .monospacedDigit()
                .foregroundStyle(.tertiary)

            HStack(alignment: .top, spacing: NotejotColors.gridUnit) {
                Text(displayTitle)
                    .font(NotejotTypography.contentBlockTitle)
                    .lineLimit(3)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Pinned")
                }
            }

            if !previewText.isEmpty {
                NoteCardExcerpt(
                    text: previewText,
                    lineLimit: note.images.isEmpty
                        ? SidebarMetrics.gridTextOnlyExcerptLineLimit
                        : SidebarMetrics.gridImageExcerptLineLimit
                )
            }

            if !note.tags.isEmpty {
                HStack(spacing: NotejotColors.gridUnit) {
                    ForEach(note.tags.prefix(6)) { tag in
                        TagMarker(tag: tag, size: 6)
                    }
                }
                .accessibilityLabel(tagAccessibilityLabel)
            }
        }
        .padding(12)
        .frame(
            maxWidth: .infinity,
            minHeight: 168,
            alignment: .topLeading
        )
        .background {
            RoundedRectangle(cornerRadius: NotejotColors.industrialRadius, style: .continuous)
                .fill(
                    NotejotColors.surface(for: colorScheme)
                )
        }
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: NotejotColors.industrialRadius, style: .continuous)
                    .strokeBorder(NotejotColors.accent, lineWidth: 2)
            }
        }
        .contentShape(.rect(cornerRadius: NotejotColors.industrialRadius))
        .animation(NotejotMotion.navigationAnimation(reduceMotion: reduceMotion), value: isSelected)
        .accessibilityElement(children: .combine)
        .task(id: note.content) {
            previewText = HTMLMapper.plainTextPreview(fromHTML: note.content)
        }
    }

    private var displayTitle: String {
        note.title.isEmpty ? String(localized: "Untitled") : note.title
    }

    private var tagAccessibilityLabel: String {
        let names = note.tags.prefix(6).map(\.name).joined(separator: ", ")
        return String(localized: "Tags: \(names)")
    }
}
