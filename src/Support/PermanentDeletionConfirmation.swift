import Foundation
import NotejotCore
import Observation

@MainActor
@Observable
final class PermanentDeletionConfirmation {
    private(set) var note: Note?
    var isPresented = false

    var noteTitle: String {
        guard let title = note?.title.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty else {
            return String(localized: "Untitled Note")
        }
        return title
    }

    func request(for note: Note) {
        guard note.isTrashed else { return }
        self.note = note
        isPresented = true
    }

    func confirm(in store: NoteStore) {
        guard let note,
              store.notes.first(where: { $0.id == note.id })?.isTrashed == true else {
            clear()
            return
        }
        store.trashNote(id: note.id)
        clear()
    }

    func clear() {
        note = nil
        isPresented = false
    }
}
