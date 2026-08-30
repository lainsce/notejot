import SwiftUI
import NotejotCore

/// A single grid cell. Keeping the action and context menu with the cell lets
/// the parent use LazyVGrid's row sizing, so every card shares a strict grid
/// baseline instead of forming independent staggered columns.
struct NoteGridCell: View {
    @Environment(NoteStore.self) private var store
    @Environment(PermanentDeletionConfirmation.self) private var deletionConfirmation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let note: Note
    let destination: Destination
    @Binding var selection: Note.ID?
    let onOpenNote: (Note.ID) -> Void

    var body: some View {
        Button {
            withAnimation(NotejotMotion.navigationAnimation(reduceMotion: reduceMotion)) {
                selection = note.id
            }
            onOpenNote(note.id)
        } label: {
            NoteCard(note: note, isSelected: selection == note.id)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Open note")
        .contextMenu {
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
}
