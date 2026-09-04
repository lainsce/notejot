import NotejotCore
import SwiftUI

struct ContentView: View {
    let store: NoteStore
    let deletionConfirmation: PermanentDeletionConfirmation
    let privacyPolicyPresenter: PrivacyPolicyPresenter

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @State private var model: NotejotSceneModel

    init(
        store: NoteStore,
        deletionConfirmation: PermanentDeletionConfirmation,
        privacyPolicyPresenter: PrivacyPolicyPresenter
    ) {
        self.store = store
        self.deletionConfirmation = deletionConfirmation
        self.privacyPolicyPresenter = privacyPolicyPresenter
        _model = State(
            initialValue: NotejotSceneModel(
                store: store,
                deletionConfirmation: deletionConfirmation
            )
        )
    }

    var body: some View {
        @Bindable var model = model
        @Bindable var deletionConfirmation = deletionConfirmation
        @Bindable var privacyPolicyPresenter = privacyPolicyPresenter

        ZStack {
            NotejotColors.windowBackground(for: colorScheme)
                .ignoresSafeArea()

            Group {
                if store.isLoaded {
                    AdaptiveNoteNavigationView(
                        notes: model.activeNotes,
                        trashedNotes: model.trashedNotes,
                        noteTagFacets: model.noteTagFacets,
                        trashTagFacets: model.trashTagFacets,
                        noteCount: model.activeNoteCount,
                        trashNoteCount: model.trashNoteCount,
                        selection: $model.selection,
                        destination: $model.destination,
                        query: $model.query,
                        selectedTagID: $model.selectedTagID,
                        viewMode: $model.viewMode,
                        isSearchPresented: $model.isSearchPresented,
                        compactPath: $model.compactPath,
                        notesCompactPath: $model.notesCompactPath,
                        trashCompactPath: $model.trashCompactPath,
                        searchFocusRequest: model.searchFocusRequest,
                        onCreateNote: model.createNote,
                        onOpenNote: model.openNote
                    )
                } else {
                    HStack(spacing: 8) {
                        NULSpinner()
                        Text("Loading Notes…")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .tint(NotejotColors.accent)
        .task {
            await model.prepare()
            NotejotWidgetDataStore.save(notes: store.notes)
        }
        .onChange(of: store.notes) {
            model.refreshFromStore()
            NotejotWidgetDataStore.save(notes: store.notes)
        }
        .onChange(of: store.lastSaveError) { oldValue, newValue in
            model.presentStoreError(oldValue, newValue)
        }
        .onChange(of: model.isShowingError) { oldValue, newValue in
            model.clearDismissedError(oldValue, newValue)
        }
        .onChange(of: deletionConfirmation.isPresented) { oldValue, newValue in
            model.clearDismissedDeletion(oldValue, newValue)
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue != .active else { return }
            Task { await store.flush() }
        }
        .alert("Notejot Error", isPresented: $model.isShowingError) {
        } message: {
            Text(model.presentedErrorMessage)
        }
        .confirmationDialog(
            "Delete \(deletionConfirmation.noteTitle) permanently?",
            isPresented: $deletionConfirmation.isPresented,
            titleVisibility: .visible
        ) {
            Button("Delete Permanently", role: .destructive) {
                deletionConfirmation.confirm(in: store)
            }
            .foregroundStyle(NotejotColors.destructive)
            Button("Cancel", role: .cancel, action: deletionConfirmation.clear)
        } message: {
            Text("This action can’t be undone.")
        }
#if os(iOS)
        .sheet(isPresented: $privacyPolicyPresenter.isPresented) {
            PrivacyPolicyView()
        }
#endif
        .focusedSceneValue(\.notejotSceneModel, model)
    }
}
