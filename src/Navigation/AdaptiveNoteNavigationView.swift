import NotejotCore
import SwiftUI

struct AdaptiveNoteNavigationView: View {
    let notes: [Note]
    let trashedNotes: [Note]
    let noteTagFacets: [TagFacet]
    let trashTagFacets: [TagFacet]
    let noteCount: Int
    let trashNoteCount: Int
    @Binding var selection: Note.ID?
    @Binding var destination: Destination
    @Binding var query: String
    @Binding var selectedTagID: TagFacet.ID?
    @Binding var viewMode: SidebarViewMode
    @Binding var isSearchPresented: Bool
    @Binding var compactPath: [CompactRoute]
    @Binding var notesCompactPath: [CompactRoute]
    @Binding var trashCompactPath: [CompactRoute]
    let searchFocusRequest: Int
    let onCreateNote: () -> Void
    let onOpenNote: (Note.ID) -> Void

    var body: some View {
#if os(iOS)
        TabView(selection: $destination) {
            Tab(value: Destination.notes) {
                IOSDestinationNavigationView(
                    contentDestination: .notes,
                    notes: notes,
                    tagFacets: noteTagFacets,
                    unfilteredNoteCount: noteCount,
                    selection: $selection,
                    selectedDestination: $destination,
                    query: $query,
                    selectedTagID: $selectedTagID,
                    viewMode: $viewMode,
                    isSearchPresented: $isSearchPresented,
                    path: $notesCompactPath,
                    searchFocusRequest: searchFocusRequest,
                    onCreateNote: onCreateNote,
                    onOpenNote: onOpenNote
                )
            } label: {
                Label("Notes", systemImage: "note.text")
            }

            Tab(value: Destination.trash) {
                IOSDestinationNavigationView(
                    contentDestination: .trash,
                    notes: trashedNotes,
                    tagFacets: trashTagFacets,
                    unfilteredNoteCount: trashNoteCount,
                    selection: $selection,
                    selectedDestination: $destination,
                    query: $query,
                    selectedTagID: $selectedTagID,
                    viewMode: $viewMode,
                    isSearchPresented: $isSearchPresented,
                    path: $trashCompactPath,
                    searchFocusRequest: searchFocusRequest,
                    onCreateNote: onCreateNote,
                    onOpenNote: onOpenNote
                )
            } label: {
                Label("Trash", systemImage: "trash")
            }
        }
        .tabBarMinimizeBehavior(.never)
#else
        MacAdaptiveNoteNavigationView(
            notes: notes,
            trashedNotes: trashedNotes,
            noteTagFacets: noteTagFacets,
            trashTagFacets: trashTagFacets,
            noteCount: noteCount,
            trashNoteCount: trashNoteCount,
            selection: $selection,
            destination: $destination,
            query: $query,
            selectedTagID: $selectedTagID,
            viewMode: $viewMode,
            isSearchPresented: $isSearchPresented,
            compactPath: $compactPath,
            searchFocusRequest: searchFocusRequest,
            onCreateNote: onCreateNote,
            onOpenNote: onOpenNote
        )
#endif
    }
}
