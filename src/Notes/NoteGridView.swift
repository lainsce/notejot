import SwiftUI
import NotejotCore

struct NoteGridView: View {
    let notes: [Note]
    let destination: Destination
    @Binding var selection: Note.ID?
    let onOpenNote: (Note.ID) -> Void

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(minimum: 0), spacing: SidebarMetrics.horizontalSpacing),
                    GridItem(.flexible(minimum: 0), spacing: SidebarMetrics.horizontalSpacing)
                ],
                alignment: .leading,
                spacing: SidebarMetrics.verticalSpacing
            ) {
                ForEach(notes) { note in
                    NoteGridCell(
                        note: note,
                        destination: destination,
                        selection: $selection,
                        onOpenNote: onOpenNote
                    )
                }
            }
            .padding(.horizontal, SidebarMetrics.horizontalInset)
            .padding(.vertical, SidebarMetrics.halfVerticalSpacing)
        }
    }
}
