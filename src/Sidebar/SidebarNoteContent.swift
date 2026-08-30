import SwiftUI
import NotejotCore

struct SidebarNoteContent: View {
    @Environment(NoteStore.self) private var store
    @Environment(PermanentDeletionConfirmation.self) private var deletionConfirmation

    let notes: [Note]
    let destination: Destination
    let query: String
    let tagFilterName: String?
    let viewMode: SidebarViewMode
    @Binding var selection: Note.ID?
    let onOpenNote: (Note.ID) -> Void
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if notes.isEmpty {
                if !query.isEmpty {
                    ContentUnavailableView.search
                        .padding(.horizontal, SidebarMetrics.horizontalInset)
                        .frame(maxHeight: .infinity)
                        .tint(.secondary)
                } else if let tagFilterName {
                    ContentUnavailableView(
                        "No Tagged Notes",
                        systemImage: "tag",
                        description: Text("No notes here use the \(tagFilterName) tag.")
                    )
                    .padding(.horizontal, SidebarMetrics.horizontalInset)
                    .frame(maxHeight: .infinity)
                    .tint(.secondary)
                } else {
                    ContentUnavailableView(
                        destination == .trash ? "Trash is Empty" : "No Notes",
                        systemImage: destination == .trash ? "trash" : "note.text"
                    )
                    .padding(.horizontal, SidebarMetrics.horizontalInset)
                    .frame(maxHeight: .infinity)
                    .tint(.secondary)
                }
            } else if viewMode == .list {
                ScrollView {
                    LazyVStack(spacing: SidebarMetrics.verticalSpacing) {
                        ForEach(notes) { note in
                            Button {
                                openNote(note.id)
                            } label: {
                                NoteRow(note: note)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        selection == note.id
                                            ? NotejotColors.surface(for: colorScheme)
                                            : NotejotColors.contentSurface,
                                        in: RoundedRectangle(
                                            cornerRadius: NotejotColors.industrialRadius,
                                            style: .continuous
                                        )
                                    )
                                    .overlay {
                                        if selection == note.id {
                                            RoundedRectangle(
                                                cornerRadius: NotejotColors.industrialRadius,
                                                style: .continuous
                                            )
                                            .strokeBorder(NotejotColors.accent, lineWidth: 1.5)
                                        }
                                    }
                                    .contentShape(
                                        .rect(cornerRadius: NotejotColors.industrialRadius)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Open note")
                            .contextMenu {
                                noteContextMenu(for: note)
                            }
                        }
                    }
                    .padding(.horizontal, SidebarMetrics.horizontalInset)
                    .padding(.vertical, SidebarMetrics.halfVerticalSpacing)
                }
            } else {
                NoteGridView(
                    notes: notes,
                    destination: destination,
                    selection: $selection,
                    onOpenNote: onOpenNote
                )
            }
        }
        .background(NotejotColors.sidebarBackground(for: colorScheme))
        .frame(maxHeight: .infinity)
        .animation(NotejotMotion.navigationAnimation(reduceMotion: reduceMotion), value: selection)
        .animation(NotejotMotion.controlAnimation(reduceMotion: reduceMotion), value: viewMode)
    }

    private func openNote(_ noteID: Note.ID) {
        withAnimation(NotejotMotion.navigationAnimation(reduceMotion: reduceMotion)) {
            selection = noteID
        }
        onOpenNote(noteID)
    }

    @ViewBuilder
    private func noteContextMenu(for note: Note) -> some View {
        if destination == .notes {
            Button(note.isPinned ? "Unpin" : "Pin") {
                store.setPinned(id: note.id, pinned: !note.isPinned)
            }
            Button("Move to Trash", role: .destructive) {
                store.trashNote(id: note.id)
            }
            .foregroundStyle(NotejotColors.destructive)
        } else {
            Button("Restore") {
                store.restoreNote(id: note.id)
            }
            Button("Delete Permanently…", role: .destructive) {
                deletionConfirmation.request(for: note)
            }
            .foregroundStyle(NotejotColors.destructive)
        }
    }
}
