import SwiftUI
import NotejotCore

struct SidebarView: View {
    @Environment(PrivacyPolicyPresenter.self) private var privacyPolicyPresenter
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let notes: [Note]
    let tagFacets: [TagFacet]
    let unfilteredNoteCount: Int
    let contentDestination: Destination
    @Binding var selection: Note.ID?
    @Binding var destination: Destination
    @Binding var query: String
    @Binding var selectedTagID: TagFacet.ID?
    @Binding var viewMode: SidebarViewMode
    @Binding var isSearchPresented: Bool
    let searchFocusRequest: Int
    let showsToolbar: Bool
    let showsDestinationMenu: Bool
    let onCreateNote: () -> Void
    let onOpenNote: (Note.ID) -> Void

    @FocusState private var isSearchFocused: Bool

    private var selectedTagName: String? {
        tagFacets.first { $0.id == selectedTagID }?.name
    }

    var body: some View {
        SidebarNoteContent(
            notes: notes,
            destination: contentDestination,
            query: query,
            tagFilterName: selectedTagName,
            viewMode: viewMode,
            selection: $selection,
            onOpenNote: onOpenNote
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            if showsToolbar {
#if os(iOS)
                if hasItems {
                    ToolbarItem(id: "sidebar-search", placement: .topBarLeading) {
                        Button(action: toggleSearch) {
                            NULIcon(systemImage: "magnifyingglass")
                        }
                        .accessibilityLabel(isSearchPresented ? "Hide Search" : "Show Search")
                        .help(isSearchPresented ? "Hide Search" : "Show Search")
                        .notejotToolbarHitTarget()
                        .nulWindowActivityAppearance()
                    }
                    .sharedBackgroundVisibility(.hidden)

                    ToolbarItem(id: "sidebar-layout", placement: .topBarTrailing) {
                        Menu {
                            Button("List View", systemImage: "list.bullet", action: showListView)
                                .disabled(viewMode == .list)
                            Button("Grid View", systemImage: "square.grid.2x2", action: showGridView)
                                .disabled(viewMode == .grid)
                        } label: {
                            NULIcon(systemImage: viewModeSystemImage)
                        }
                        .accessibilityLabel("View")
                        .accessibilityValue(Text(viewModeAccessibilityValue))
                        .help("View Options")
                        .notejotToolbarHitTarget()
                        .nulWindowActivityAppearance()
                    }
                    .sharedBackgroundVisibility(.hidden)
                }

                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: createItem) {
                            NULIcon(systemImage: "plus", foregroundColor: NotejotColors.accent)
                    }
                        .accessibilityLabel(createButtonLabel)
                        .tint(NotejotColors.accent)
                        .help(createButtonHelp)
                        .notejotToolbarHitTarget()
                        .contentShape(Rectangle())
                        .nulWindowActivityAppearance()

                    Menu {
                        Button("Privacy Policy", action: showPrivacyPolicy)
                    } label: {
                        NULIcon(systemImage: "ellipsis")
                    }
                    .accessibilityLabel("More")
                    .help("More")
                    .notejotToolbarHitTarget()
                    .nulWindowActivityAppearance()
                }
                .sharedBackgroundVisibility(.hidden)
#else
                if !showsDestinationMenu {
                    // The transparent destination lane has no controls. A
                    // fixed reservation keeps the middle-sidebar group from
                    // drifting as the window is resized.
                    ToolbarItem(placement: .navigation) {
                        Color.clear
                            .frame(width: SidebarMetrics.toolbarDestinationReservation, height: 1)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                    .sharedBackgroundVisibility(.hidden)
                }

                if hasItems {
                    if showsDestinationMenu {
                        ToolbarItem(placement: .navigation) {
                            appDestinationMenu
                        }
                        .sharedBackgroundVisibility(.hidden)
                        ToolbarSpacer(.fixed, placement: .navigation)
                            .sharedBackgroundVisibility(.hidden)
                    }

                    ToolbarItem(placement: .navigation) {
                        MacSidebarToolbar(
                            isSearchPresented: isSearchPresented,
                            toggleSearch: toggleSearch,
                            viewMode: $viewMode,
                            createButtonLabel: createButtonLabel,
                            createButtonHelp: createButtonHelp,
                            createItem: createItem,
                            distributesAcrossLane: !showsDestinationMenu
                        )
                    }
                    .sharedBackgroundVisibility(.hidden)

                } else {
                    // With no items, leave the navigation lane empty after
                    // its destination control and keep creation at the
                    // trailing primary-action position.
                    ToolbarItemGroup(placement: .navigation) {
                        if showsDestinationMenu {
                            appDestinationMenu
                        }
                    }
                    .sharedBackgroundVisibility(.hidden)

                    ToolbarItem(placement: .primaryAction) {
                        Button(action: createItem) {
                            NULIcon(
                                systemImage: "plus",
                                foregroundColor: .black
                            )
                        }
                        .accessibilityLabel(createButtonLabel)
                        .buttonStyle(.plain)
                        .frame(
                            width: NotejotLayoutMetrics.compactToolbarControlSize,
                            height: NotejotLayoutMetrics.compactToolbarControlSize
                        )
                        .background(
                            NotejotColors.accent,
                            in: RoundedRectangle(
                                cornerRadius: NotejotColors.industrialSmallRadius,
                                style: .continuous
                            )
                        )
                        .contentShape(Rectangle())
                        .help(createButtonHelp)
                        .padding(.leading, 8)
                        .nulWindowActivityAppearance()
                    }
                    .sharedBackgroundVisibility(.hidden)
                }

#endif
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                if isSearchPresented {
                    NULSearchField(
                        text: $query,
                        prompt: searchPrompt,
                        focusLabel: searchPrompt,
                        isFocused: $isSearchFocused
                    )
                    .padding(.horizontal, SidebarMetrics.horizontalInset)
                    .padding(.vertical, SidebarMetrics.halfVerticalSpacing)
                }

#if os(iOS)
                if !tagFacets.isEmpty {
                    TagFilterShelf(
                        facets: tagFacets,
                        allNoteCount: unfilteredNoteCount,
                        selection: $selectedTagID
                    )
                }
#endif
            }
        }
#if os(macOS)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            QuickNoteComposer()
        }
#endif
        .toolbar(removing: .title)
        .onChange(of: isSearchPresented) { _, newValue in
            updateSearchPresentation(newValue)
        }
        .onChange(of: searchFocusRequest) {
            isSearchFocused = true
        }
    }

    private var viewModeSystemImage: String {
        viewMode == .list ? "list.bullet" : "square.grid.2x2"
    }

    private var hasItems: Bool {
        !notes.isEmpty
    }

    @ViewBuilder
    private var appDestinationMenu: some View {
        NULMenuButton(
            accessibilityLabel: "App destinations",
            label: {
                HStack(spacing: NotejotColors.gridUnit) {
                    NULIcon(
                        systemImage: destination == .trash ? "trash" : "note.text"
                    )
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
            },
            menuContent: {
                Button(action: showAllNotes) {
                    Label("All Notes", systemImage: "note.text")
                }

                Menu("Tags", systemImage: "tag") {
                    if tagFacets.isEmpty {
                        Button("No Tags", action: {})
                            .disabled(true)
                    } else {
                        ForEach(tagFacets) { facet in
                            Button(facet.name) {
                                showTag(facet.id)
                            }
                        }
                    }
                }

                Divider()
                Button(action: showTrash) {
                    Label("Trash", systemImage: "trash")
                }
            }
        )
        .help("App destinations")
    }

    private var createButtonLabel: LocalizedStringKey {
        "New Note"
    }

    private var searchPrompt: LocalizedStringKey {
        "Search Notes"
    }

    private var createButtonHelp: LocalizedStringKey {
        "New Note (⌘N)"
    }

    private var viewModeAccessibilityValue: LocalizedStringKey {
        viewMode == .list ? "List" : "Grid"
    }

    private func createItem() {
        onCreateNote()
    }

    private func showListView() {
        withAnimation(NotejotMotion.controlAnimation(reduceMotion: reduceMotion)) {
            viewMode = .list
        }
    }

    private func showGridView() {
        withAnimation(NotejotMotion.controlAnimation(reduceMotion: reduceMotion)) {
            viewMode = .grid
        }
    }

    private func showAllNotes() {
        withAnimation(NotejotMotion.navigationAnimation(reduceMotion: reduceMotion)) {
            selectedTagID = nil
            destination = .notes
        }
    }

    private func showTag(_ tagID: TagFacet.ID) {
        withAnimation(NotejotMotion.navigationAnimation(reduceMotion: reduceMotion)) {
            selectedTagID = tagID
            destination = .notes
        }
    }

    private func showTrash() {
        withAnimation(NotejotMotion.navigationAnimation(reduceMotion: reduceMotion)) {
            selectedTagID = nil
            destination = .trash
        }
    }

    private func toggleSearch() {
        withAnimation(NotejotMotion.controlAnimation(reduceMotion: reduceMotion)) {
            isSearchPresented.toggle()
        }
    }

    private func updateSearchPresentation(_ isPresented: Bool) {
        isSearchFocused = isPresented
        if !isPresented {
            query = ""
        }
    }

    private func showPrivacyPolicy() {
        privacyPolicyPresenter.show()
    }
}
