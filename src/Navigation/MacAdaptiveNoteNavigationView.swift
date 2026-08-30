#if os(macOS)
import NotejotCore
import SwiftUI

struct MacAdaptiveNoteNavigationView: View {
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
    let searchFocusRequest: Int
    let onCreateNote: () -> Void
    let onOpenNote: (Note.ID) -> Void

    @State private var usesCompactNavigation = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if usesCompactNavigation {
                NavigationStack(path: $compactPath) {
                    SidebarView(
                        notes: displayedNotes,
                        tagFacets: displayedTagFacets,
                        unfilteredNoteCount: displayedNoteCount,
                        contentDestination: destination,
                        selection: $selection,
                        destination: $destination,
                        query: $query,
                        selectedTagID: $selectedTagID,
                        viewMode: $viewMode,
                        isSearchPresented: $isSearchPresented,
                        searchFocusRequest: searchFocusRequest,
                        showsToolbar: compactPath.isEmpty,
                        showsDestinationMenu: true,
                        onCreateNote: onCreateNote,
                        onOpenNote: onOpenNote
                    )
                    .navigationDestination(for: CompactRoute.self) { route in
                        compactDestination(for: route)
                    }
                }
            } else {
                fixedWideNavigation
            }
        }
        .animation(NotejotMotion.navigationAnimation(reduceMotion: reduceMotion), value: usesCompactNavigation)
        .onGeometryChange(for: Bool.self) { proxy in
            proxy.size.width < SidebarMetrics.wideNavigationMinimumWidth
        } action: { newValue in
            usesCompactNavigation = newValue
        }
    }

    private var displayedNotes: [Note] {
        destination == .trash ? trashedNotes : notes
    }

    private var displayedTagFacets: [TagFacet] {
        destination == .trash ? trashTagFacets : noteTagFacets
    }

    private var displayedNoteCount: Int {
        destination == .trash ? trashNoteCount : noteCount
    }

    // NavigationSplitView treats column widths as preferences and keeps its
    // splitters interactive. A fixed HStack preserves the three-column layout
    // without exposing resize or collapse affordances to the user.
    private var fixedWideNavigation: some View {
        HStack(spacing: 0) {
            MacDestinationSidebar(
                tagFacets: noteTagFacets,
                destination: $destination,
                selectedTagID: $selectedTagID
            )
            .frame(width: SidebarMetrics.destinationWidth)

            SidebarView(
                notes: displayedNotes,
                tagFacets: displayedTagFacets,
                unfilteredNoteCount: displayedNoteCount,
                contentDestination: destination,
                selection: $selection,
                destination: $destination,
                query: $query,
                selectedTagID: $selectedTagID,
                viewMode: $viewMode,
                isSearchPresented: $isSearchPresented,
                searchFocusRequest: searchFocusRequest,
                showsToolbar: true,
                showsDestinationMenu: false,
                onCreateNote: onCreateNote,
                onOpenNote: onOpenNote
            )
            .frame(width: SidebarMetrics.width)

            WideDetailView(
                destination: destination,
                notes: displayedNotes,
                noteSelection: selection
            )
            .equatable()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Pane dividers normally begin below the window toolbar because each
        // child contributes its own toolbar content. Keep both fixed column
        // boundaries continuous so the toolbar lanes read as part of their
        // respective columns as well.
        .overlay(alignment: .topLeading) {
            Rectangle()
                .fill(NotejotColors.sidebarDivider(for: colorScheme))
                .frame(width: 1)
                .frame(maxHeight: .infinity)
                .offset(x: SidebarMetrics.destinationWidth)
                .ignoresSafeArea(.container, edges: .top)
                .allowsHitTesting(false)
                .zIndex(1)

            Rectangle()
                .fill(NotejotColors.sidebarDivider(for: colorScheme))
                .frame(width: 1)
                .frame(maxHeight: .infinity)
                .offset(x: SidebarMetrics.destinationWidth + SidebarMetrics.width)
                .ignoresSafeArea(.container, edges: .top)
                .allowsHitTesting(false)
                .zIndex(1)
        }
        .notejotSidebarToggleRemoved()
    }

    @ViewBuilder
    private func compactDestination(for route: CompactRoute) -> some View {
        switch route {
        case .note(let noteID):
            if let note = displayedNotes.first(where: { $0.id == noteID }) {
                NoteDetailView(note: note, usesCompactLayout: true)
                    .id(note.id)
            } else {
                ContentUnavailableView(
                    "Note Unavailable",
                    systemImage: "note.text",
                    description: Text("Return to the sidebar to choose another note.")
                )
                .tint(.secondary)
            }
        }
    }
}

#endif
