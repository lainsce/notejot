import NotejotCore
import Observation

@MainActor
@Observable
final class NotejotSceneModel {
    @ObservationIgnored private let store: NoteStore
    @ObservationIgnored private let deletionConfirmation: PermanentDeletionConfirmation

    var selection: Note.ID?
    var destination: Destination = .notes {
        didSet {
            guard destination != oldValue else { return }
            recomputePresentation()
            updateDestination(destination)
        }
    }
    var query = "" {
        didSet {
            guard query != oldValue else { return }
            recomputePresentation()
        }
    }
    var selectedTagID: TagFacet.ID? {
        didSet {
            guard selectedTagID != oldValue, !isRecomputingPresentation else { return }
            recomputePresentation()
        }
    }
    var viewMode: SidebarViewMode = .list
    var isSearchPresented = false
    var searchFocusRequest = 0
    var compactPath: [CompactRoute] = []
    var notesCompactPath: [CompactRoute] = []
    var trashCompactPath: [CompactRoute] = []
    var isShowingError = false
    var presentedErrorMessage = ""

    private(set) var activeNotes: [Note] = []
    private(set) var trashedNotes: [Note] = []
    private(set) var noteTagFacets: [TagFacet] = []
    private(set) var trashTagFacets: [TagFacet] = []
    private(set) var activeNoteCount = 0
    private(set) var trashNoteCount = 0

    @ObservationIgnored private var sourceNotes: [Note] = []
    @ObservationIgnored private var isRecomputingPresentation = false

    init(
        store: NoteStore,
        deletionConfirmation: PermanentDeletionConfirmation
    ) {
        self.store = store
        self.deletionConfirmation = deletionConfirmation
    }

    var hasSelection: Bool {
        selectedNote != nil
    }

    var selectedNoteIsPinned: Bool {
        selectedNote?.isPinned == true
    }

    var selectedNoteIsTrashed: Bool {
        selectedNote?.isTrashed == true
    }

    func prepare() async {
        await store.load()
        store.seedWelcomeNoteIfEmpty()
        refreshFromStore()
        if selection == nil { selection = shownNotes.first?.id }
        presentStoreError()
    }

    func refreshFromStore() {
        sourceNotes = store.notes
        recomputePresentation()
        updateSelection(for: shownNotes.map(\.id))
    }

    func createNote() {
        destination = .notes
        query = ""
        selectedTagID = nil
        let noteID = store.createNote().id
        refreshFromStore()
        selection = noteID
        compactPath = [.note(noteID)]
        notesCompactPath = [.note(noteID)]
    }

    func openNote(_ noteID: Note.ID) {
        compactPath = [.note(noteID)]
        if destination == .trash {
            trashCompactPath = [.note(noteID)]
        } else {
            notesCompactPath = [.note(noteID)]
        }
    }

    func searchNotes() {
        isSearchPresented = true
        searchFocusRequest += 1
    }

    func toggleSearch() {
        isSearchPresented.toggle()
    }

    func showNotes() {
        destination = .notes
    }

    func showTrash() {
        destination = .trash
    }

    func showList() {
        viewMode = .list
    }

    func showGrid() {
        viewMode = .grid
    }

    func togglePin() {
        guard let selectedNote, !selectedNote.isTrashed else { return }
        store.setPinned(id: selectedNote.id, pinned: !selectedNote.isPinned)
    }

    func moveToTrash() {
        guard let selectedNote, !selectedNote.isTrashed else { return }
        store.trashNote(id: selectedNote.id)
    }

    func restore() {
        guard let selectedNote, selectedNote.isTrashed else { return }
        store.restoreNote(id: selectedNote.id)
    }

    func requestPermanentDeletion() {
        guard let selectedNote, selectedNote.isTrashed else { return }
        deletionConfirmation.request(for: selectedNote)
    }

    func presentStoreError(_ oldValue: String?, _ newValue: String?) {
        guard newValue != oldValue else { return }
        presentStoreError()
    }

    func clearDismissedError(_ oldValue: Bool, _ newValue: Bool) {
        guard oldValue, !newValue else { return }
        store.acknowledgeSaveError()
    }

    func clearDismissedDeletion(_ oldValue: Bool, _ newValue: Bool) {
        guard oldValue, !newValue, deletionConfirmation.note != nil else { return }
        deletionConfirmation.clear()
    }

    private var shownNotes: [Note] {
        destination == .trash ? trashedNotes : activeNotes
    }

    private var selectedNote: Note? {
        guard let selection else { return nil }
        return sourceNotes.first { $0.id == selection }
    }

    private func recomputePresentation() {
        guard !isRecomputingPresentation else { return }
        isRecomputingPresentation = true
        defer { isRecomputingPresentation = false }

        noteTagFacets = TagFacet.available(in: sourceNotes, destination: .notes)
        trashTagFacets = TagFacet.available(in: sourceNotes, destination: .trash)

        let availableFacets = destination == .trash ? trashTagFacets : noteTagFacets
        if let selectedTagID, !availableFacets.contains(where: { $0.id == selectedTagID }) {
            self.selectedTagID = nil
        }

        activeNotes = NoteFilter.matching(
            sourceNotes,
            destination: .notes,
            query: query,
            tag: selectedTagID
        )
        trashedNotes = NoteFilter.matching(
            sourceNotes,
            destination: .trash,
            query: query,
            tag: selectedTagID
        )
        activeNoteCount = sourceNotes.count { !$0.isTrashed }
        trashNoteCount = sourceNotes.count(where: \.isTrashed)
    }

    private func updateSelection(for visibleIDs: [Note.ID]) {
        if case .some(.note(let presentedNoteID)) = compactPath.last,
           !visibleIDs.contains(presentedNoteID) {
            compactPath.removeAll()
        }

        switch destination {
        case .notes:
            if case .some(.note(let presentedNoteID)) = notesCompactPath.last,
               !visibleIDs.contains(presentedNoteID) {
                notesCompactPath.removeAll()
            }
        case .trash:
            if case .some(.note(let presentedNoteID)) = trashCompactPath.last,
               !visibleIDs.contains(presentedNoteID) {
                trashCompactPath.removeAll()
            }
        }

        guard let selection else {
            self.selection = visibleIDs.first
            return
        }
        guard !visibleIDs.contains(selection) else { return }
        self.selection = visibleIDs.first
    }

    private func updateDestination(_ newDestination: Destination) {
        switch newDestination {
        case .notes, .trash:
            if case .some(.note) = compactPath.last {
                updateSelection(for: shownNotes.map(\.id))
            } else {
                compactPath.removeAll()
            }
            if selection == nil {
                selection = shownNotes.first?.id
            }
        }
    }

    private func presentStoreError() {
        guard let message = store.lastSaveError else { return }
        presentedErrorMessage = message
        isShowingError = true
    }
}
