#if os(iOS)
import NotejotCore
import SwiftUI

struct IOSDestinationNavigationView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let contentDestination: Destination
    let notes: [Note]
    let tagFacets: [TagFacet]
    let unfilteredNoteCount: Int
    @Binding var selection: Note.ID?
    @Binding var selectedDestination: Destination
    @Binding var query: String
    @Binding var selectedTagID: TagFacet.ID?
    @Binding var viewMode: SidebarViewMode
    @Binding var isSearchPresented: Bool
    @Binding var path: [CompactRoute]
    let searchFocusRequest: Int
    let onCreateNote: () -> Void
    let onOpenNote: (Note.ID) -> Void

    var body: some View {
        if horizontalSizeClass == .regular {
            NavigationSplitView(columnVisibility: .constant(.all)) {
                sidebar(showsToolbar: true)
                    .navigationSplitViewColumnWidth(SidebarMetrics.width)
            } detail: {
                WideDetailView(
                    destination: contentDestination,
                    notes: notes,
                    noteSelection: selection
                )
                .equatable()
            }
        } else {
            NavigationStack(path: $path) {
                sidebar(showsToolbar: path.isEmpty)
                    .navigationDestination(for: CompactRoute.self) { route in
                        switch route {
                        case .note(let noteID):
                            if let note = notes.first(where: { $0.id == noteID }) {
                                NoteDetailView(note: note, usesCompactLayout: true)
                                    .id(note.id)
                            } else {
                                ContentUnavailableView(
                                    "Note Unavailable",
                                    systemImage: "note.text",
                                    description: Text("Return to this tab to choose another note.")
                                )
                                .tint(.secondary)
                            }
                        }
                    }
            }
        }
    }

    private func sidebar(showsToolbar: Bool) -> some View {
        SidebarView(
            notes: notes,
            tagFacets: tagFacets,
            unfilteredNoteCount: unfilteredNoteCount,
            contentDestination: contentDestination,
            selection: $selection,
            destination: $selectedDestination,
            query: $query,
            selectedTagID: $selectedTagID,
            viewMode: $viewMode,
            isSearchPresented: $isSearchPresented,
            searchFocusRequest: searchFocusRequest,
            showsToolbar: showsToolbar,
            showsDestinationMenu: false,
            onCreateNote: onCreateNote,
            onOpenNote: onOpenNote
        )
    }
}
#endif
