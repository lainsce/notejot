import NotejotCore
import SwiftUI

struct WideDetailView: View, Equatable {
    let destination: Destination
    let notes: [Note]
    let noteSelection: Note.ID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.destination == rhs.destination
            && lhs.notes == rhs.notes
            && lhs.noteSelection == rhs.noteSelection
    }

    private var selectedNote: Note? {
        notes.first { $0.id == noteSelection } ?? notes.first
    }

    var body: some View {
        Group {
            if let selectedNote {
                NoteDetailView(note: selectedNote)
                    .id(selectedNote.id)
            } else {
                ContentUnavailableView(
                    "No Note Selected",
                    systemImage: "note.text",
                    description: Text("Select a note or press ⌘N.")
                )
                .tint(.secondary)
            }
        }
        // The navigation lens animates independently. Do not let its transaction
        // fade the entire editor surface when the destination changes.
        .transaction(value: destination) { transaction in
            transaction.animation = NotejotMotion.navigationAnimation(reduceMotion: reduceMotion)
        }
    }
}
