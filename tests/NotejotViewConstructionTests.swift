import AppKit
import NotejotCore
import SwiftUI
import XCTest
@testable import Notejot

final class NotejotViewConstructionTests: XCTestCase {
    @MainActor
    private func sampleNotes() -> [Note] {
        let tags = [
            Tag(id: "work", color: "#4A90D9", name: "Work"),
            Tag(id: "ideas", color: "#F6D32D", name: "Ideas")
        ]
        return [
            Note(
                id: "n1",
                title: "A note",
                content: "<p>Hello <strong>world</strong>.</p>",
                isPinned: true,
                tags: tags,
                images: ["data:image/png;base64,invalid"]
            ),
            Note(id: "n2", title: "", content: "<p>Plain</p>", isTrashed: true)
        ]
    }

    @MainActor
    func testConstructsNoteCardsAndNavigationSurfaces() {
        let notes = sampleNotes()
        let store = NoteStore(directory: FileManager.default.temporaryDirectory.appending(path: "NotejotViews-\(UUID().uuidString)"))
        _ = PermanentDeletionConfirmation()
        let presenter = PrivacyPolicyPresenter()
        var selection: Note.ID? = notes[0].id
        var destination: Destination = .notes
        var query = ""
        var selectedTagID: TagFacet.ID?
        var viewMode: SidebarViewMode = .list
        var searchPresented = false
        var path: [CompactRoute] = []
        var notesPath: [CompactRoute] = []
        var trashPath: [CompactRoute] = []

        _ = NoteCard(note: notes[0], isSelected: true).body
        _ = NoteCard(note: notes[1], isSelected: false).body
        _ = NoteCardExcerpt(text: "Excerpt", lineLimit: 2).body
        _ = NoteCardAttachment(source: notes[0].images[0], noteTitle: "A note").body
        _ = NoteRow(note: notes[0]).body
        _ = NoteRow(note: notes[1]).body
        _ = NoteGridView(notes: notes, destination: .notes, selection: .constant(notes[0].id), onOpenNote: { _ in }).body
        _ = NoteGridCell(note: notes[0], destination: .notes, selection: .constant(notes[0].id), onOpenNote: { _ in }).body
        _ = NoteGridCell(note: notes[1], destination: .trash, selection: .constant(notes[1].id), onOpenNote: { _ in }).body
        _ = SidebarNoteContent(
            notes: [], destination: .notes, query: "", tagFilterName: nil,
            viewMode: .list, selection: .constant(nil), onOpenNote: { _ in }
        )
        _ = SidebarNoteContent(
            notes: [], destination: .trash, query: "needle", tagFilterName: nil,
            viewMode: .list, selection: .constant(nil), onOpenNote: { _ in }
        )
        _ = SidebarNoteContent(
            notes: [], destination: .notes, query: "", tagFilterName: "Work",
            viewMode: .list, selection: .constant(nil), onOpenNote: { _ in }
        )
        _ = SidebarNoteContent(
            notes: notes, destination: .notes, query: "", tagFilterName: nil,
            viewMode: .list, selection: .constant(notes[0].id), onOpenNote: { _ in }
        )
        _ = SidebarNoteContent(
            notes: notes, destination: .trash, query: "", tagFilterName: nil,
            viewMode: .grid, selection: .constant(notes[1].id), onOpenNote: { _ in }
        )

        _ = SidebarView(
            notes: notes,
            tagFacets: [],
            unfilteredNoteCount: notes.count,
            contentDestination: .notes,
            selection: Binding(get: { selection }, set: { selection = $0 }),
            destination: Binding(get: { destination }, set: { destination = $0 }),
            query: Binding(get: { query }, set: { query = $0 }),
            selectedTagID: Binding(get: { selectedTagID }, set: { selectedTagID = $0 }),
            viewMode: Binding(get: { viewMode }, set: { viewMode = $0 }),
            isSearchPresented: Binding(get: { searchPresented }, set: { searchPresented = $0 }),
            searchFocusRequest: 0,
            showsToolbar: true,
            showsDestinationMenu: true,
            onCreateNote: {},
            onOpenNote: { _ in }
        ).environment(presenter).environment(store)

        _ = MacSidebarToolbar(
            isSearchPresented: false,
            toggleSearch: {},
            viewMode: .constant(.list),
            createButtonLabel: "New Note",
            createButtonHelp: "New Note",
            createItem: {},
            distributesAcrossLane: true
        ).body
        _ = MacSidebarToolbar(
            isSearchPresented: true,
            toggleSearch: {},
            viewMode: .constant(.grid),
            createButtonLabel: "New Note",
            createButtonHelp: "New Note",
            createItem: {},
            distributesAcrossLane: false
        ).body

        _ = MacDestinationSidebar(tagFacets: [], destination: .constant(.notes), selectedTagID: .constant(nil)).body
        _ = MacDestinationSidebar(
            tagFacets: [TagFacet(tag: tagsForTest()[0], count: 2)],
            destination: .constant(.trash),
            selectedTagID: .constant(nil)
        ).body
        _ = WideDetailView(destination: .notes, notes: notes, noteSelection: notes[0].id).body
        _ = WideDetailView(destination: .trash, notes: [], noteSelection: nil).body
        _ = MacAdaptiveNoteNavigationView(
            notes: notes,
            trashedNotes: [notes[1]],
            noteTagFacets: [],
            trashTagFacets: [],
            noteCount: 1,
            trashNoteCount: 1,
            selection: .constant(notes[0].id),
            destination: .constant(.notes),
            query: .constant(""),
            selectedTagID: .constant(nil),
            viewMode: .constant(.list),
            isSearchPresented: .constant(false),
            compactPath: Binding(get: { path }, set: { path = $0 }),
            searchFocusRequest: 0,
            onCreateNote: {},
            onOpenNote: { _ in }
        ).environment(presenter).environment(store)
        _ = AdaptiveNoteNavigationView(
            notes: notes,
            trashedNotes: [notes[1]],
            noteTagFacets: [],
            trashTagFacets: [],
            noteCount: 1,
            trashNoteCount: 1,
            selection: .constant(notes[0].id),
            destination: .constant(destination),
            query: .constant(""),
            selectedTagID: .constant(nil),
            viewMode: .constant(.list),
            isSearchPresented: .constant(false),
            compactPath: Binding(get: { path }, set: { path = $0 }),
            notesCompactPath: Binding(get: { notesPath }, set: { notesPath = $0 }),
            trashCompactPath: Binding(get: { trashPath }, set: { trashPath = $0 }),
            searchFocusRequest: 0,
            onCreateNote: {},
            onOpenNote: { _ in }
        ).environment(presenter).environment(store)
    }

    @MainActor
    func testConstructsTagsPaperImagesAndEditorViews() {
        let notes = sampleNotes()
        let note = notes[0]
        let store = NoteStore(directory: FileManager.default.temporaryDirectory.appending(path: "NotejotTagViews-\(UUID().uuidString)"))
        let tags = tagsForTest()

        _ = TagMarker(tag: tags[0], size: 8).body
        _ = TagColorSwatch(hex: "#4A90D9", name: "Blue", isSelected: true, action: {}).body
        _ = TagColorSwatch(hex: "bad", name: "Fallback", isSelected: false, action: {}).body
        _ = TagFilterChip(tag: nil, count: 2, isSelected: true, action: {}).body
        _ = TagFilterChip(tag: tags[0], count: 1, isSelected: false, action: {}).body
        _ = TagPill(tag: tags[0], onRemove: {}).body
        _ = AvailableTagRow(facet: TagFacet(tag: tags[1], count: 3), action: {}).body
        _ = TagFilterShelf(facets: [TagFacet(tag: tags[0], count: 1)], allNoteCount: 2, selection: .constant(nil)).body
        _ = TagPopoverView(note: note).environment(store)

        _ = PaperclipBodyShape().path(in: CGRect(x: 0, y: 0, width: 27, height: 57))
        _ = PaperclipView().body
        _ = QuantumPaperBackground().body
        _ = ClipPrintView(source: note.images[0], index: 0, total: 2).body
        _ = ClipStackView(note: note).body

        _ = DataURLImage(source: note.images[0], accessibilityLabel: "Attachment").body
        _ = ImageFlyoutCell(note: note, source: note.images[0], index: 0, onRemoveLastImage: {}).environment(store)
        _ = ImageFlyoutView(note: note).body
        _ = ImageFlyoutView(note: Note(id: "single", images: [note.images[0]])).body

        _ = NoteDetailView(note: note, usesCompactLayout: false).environment(store).environment(PermanentDeletionConfirmation())
        _ = NoteDetailView(note: Note(id: "trash", isTrashed: true), usesCompactLayout: true).environment(store).environment(PermanentDeletionConfirmation())
        let formatter = EditorFormattingController()
        _ = CompactEditorFormattingBar(
            formatter: formatter,
            canAddImage: true,
            addImage: {},
            isShowingTagPopover: .constant(false),
            note: note
        ).body
        _ = NotejotAboutView().body
        _ = PrivacyPolicyView().body
        _ = PrivacyPolicySection(title: "Local", systemImage: "lock", text: "Stored locally").body
        _ = NULFormRow("Field") { Text("Value") }.body
        _ = NULIcon(systemImage: "plus", foregroundColor: NotejotColors.accent).body
        _ = NULSpinner().body
        _ = NULMenuButton(accessibilityLabel: "More", label: { NULIcon(systemImage: "ellipsis") }, menuContent: { Text("Menu") }).body
        _ = NULSegmentedPicker(selection: .constant(SidebarViewMode.list), options: [.list, .grid]) { mode in
            Text(mode == .list ? "List" : "Grid")
        }.body
        _ = NULSidebarSurface().body
        _ = Text("Surface").modifier(NULWindowActivityAppearance())
    }

    @MainActor
    func testContentViewAndPrivacyPresenterConstruction() {
        let store = NoteStore(directory: FileManager.default.temporaryDirectory.appending(path: "NotejotContentViews-\(UUID().uuidString)"))
        let deletion = PermanentDeletionConfirmation()
        let presenter = PrivacyPolicyPresenter()
        _ = ContentView(store: store, deletionConfirmation: deletion, privacyPolicyPresenter: presenter).body
        presenter.show()
        XCTAssertTrue(presenter.isPresented)
    }

    @MainActor
    func testRendersNuulControlsThroughSwiftUI() {
        func assertRenders<Control: View>(_ control: Control) {
            let renderer = ImageRenderer(content: control
                .environment(\.colorScheme, .dark))
            renderer.scale = 1
            XCTAssertNotNil(renderer.nsImage)
        }

        assertRenders(Button(action: {}) { Text("Primary") }.buttonStyle(NULButtonStyle(kind: .primary)))
        assertRenders(Button(action: {}) { Text("Neutral") }.buttonStyle(NULButtonStyle(kind: .neutral)))
        assertRenders(Button(action: {}) { Text("Quiet") }.buttonStyle(NULButtonStyle(kind: .quiet)))
        assertRenders(Button(action: {}) { Text("Disabled") }.buttonStyle(NULButtonStyle()).disabled(true))
        assertRenders(Toggle("Toggle", isOn: .constant(true)).toggleStyle(NULToggleStyle()))
        assertRenders(Toggle("Toggle", isOn: .constant(false)).toggleStyle(NULToggleStyle()))
        assertRenders(TextField("Field", text: .constant("Value")).textFieldStyle(NULTextFieldStyle()))
        assertRenders(NULIcon(systemImage: "plus", foregroundColor: NotejotColors.accent))
        assertRenders(NULSpinner())
        assertRenders(NULSegmentedPicker(selection: .constant(SidebarViewMode.list), options: [.list, .grid]) {
            Text(verbatim: $0 == .list ? "List" : "Grid")
        })
        assertRenders(Button(action: {}) { Text("Sidebar") }.buttonStyle(NULSidebarButtonStyle(isSelected: true, isHovered: true)))
    }

    @MainActor
    private func tagsForTest() -> [Tag] {
        [
            Tag(id: "work", color: "#4A90D9", name: "Work"),
            Tag(id: "ideas", color: "#F6D32D", name: "Ideas")
        ]
    }
}
