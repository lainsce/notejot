import NotejotCore
import SwiftUI

struct NotejotMenuCommands: Commands {
    @FocusedValue(\.notejotSceneModel) private var sceneModel
    @FocusedValue(\.notejotEditorController) private var editorController
    @FocusedValue(\.notejotDetailActions) private var detailActions
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
#if os(macOS)
        CommandGroup(replacing: .appInfo) {
            Button("About \(NotejotAppInfo.applicationName)", systemImage: "info.circle") {
                openWindow(id: NotejotWindowID.about)
            }
        }

        CommandGroup(after: .help) {
            Divider()
            Button("Privacy Policy", systemImage: "hand.raised") {
                openWindow(id: NotejotWindowID.privacyPolicy)
            }
        }
#endif

        CommandGroup(replacing: .newItem) {
            Button("New Note", action: createNote)
                .keyboardShortcut("n", modifiers: .command)
                .disabled(sceneModel == nil)
        }

        CommandGroup(after: .newItem) {
            if sceneModel?.destination == .trash {
                Divider()
                Button("Restore", action: restore)
                    .disabled(sceneModel?.selectedNoteIsTrashed != true)
                Button("Delete Permanently…", role: .destructive, action: requestPermanentDeletion)
                    .foregroundStyle(NotejotColors.destructive)
                    .disabled(sceneModel?.selectedNoteIsTrashed != true)
            } else if sceneModel?.destination == .notes {
                Divider()
                Button(sceneModel?.selectedNoteIsPinned == true ? "Unpin Note" : "Pin Note", action: togglePin)
                    .disabled(sceneModel?.hasSelection != true || sceneModel?.selectedNoteIsTrashed == true)
                Button("Move to Trash", role: .destructive, action: moveToTrash)
                    .foregroundStyle(NotejotColors.destructive)
                    .disabled(sceneModel?.hasSelection != true || sceneModel?.selectedNoteIsTrashed == true)
            }
        }

        CommandGroup(after: .pasteboard) {
            Divider()
            Button(searchCommandTitle, action: searchNotes)
                .keyboardShortcut("f", modifiers: .command)
                .disabled(sceneModel == nil)
        }

        CommandGroup(replacing: .textFormatting) {
            Button("Bold", action: toggleBold)
                .keyboardShortcut("b", modifiers: .command)
                .disabled(editorController == nil)
            Button("Italic", action: toggleItalic)
                .keyboardShortcut("i", modifiers: .command)
                .disabled(editorController == nil)
            Button("Underline", action: toggleUnderline)
                .keyboardShortcut("u", modifiers: .command)
                .disabled(editorController == nil)
            Button("Strikethrough", action: toggleStrikethrough)
                .keyboardShortcut("x", modifiers: [.command, .shift])
                .disabled(editorController == nil)
            Divider()
            Button("Bulleted List", action: toggleBulletedList)
                .disabled(editorController == nil)
            Menu("Heading Style") {
                Button("Normal Text") { applyHeading(0) }
                Divider()
                Button("Heading 1") { applyHeading(1) }
                Button("Heading 2") { applyHeading(2) }
                Button("Heading 3") { applyHeading(3) }
            }
            .disabled(editorController == nil)
        }

        CommandMenu("Insert") {
            Button("Add Image…", action: addImage)
                .disabled(detailActions?.canAddImage != true)
            Button("Add Tag…", action: addTag)
                .disabled(detailActions == nil)
        }

        CommandGroup(after: .sidebar) {
            Button(sceneModel?.isSearchPresented == true ? "Hide Search" : "Show Search", action: toggleSearch)
                .disabled(sceneModel == nil)
            Divider()
            Button("Show Notes", action: showNotes)
                .keyboardShortcut("1", modifiers: .command)
                .disabled(sceneModel == nil || sceneModel?.destination == .notes)
            Button("Show Trash", action: showTrash)
                .keyboardShortcut("2", modifiers: .command)
                .disabled(sceneModel == nil || sceneModel?.destination == .trash)
            Divider()
            Button("List View", action: showList)
                .disabled(sceneModel == nil || sceneModel?.viewMode == .list)
            Button("Grid View", action: showGrid)
                .disabled(sceneModel == nil || sceneModel?.viewMode == .grid)
        }
    }

    private func createNote() { sceneModel?.createNote() }
    private func searchNotes() { sceneModel?.searchNotes() }
    private func toggleSearch() { sceneModel?.toggleSearch() }
    private func showNotes() { sceneModel?.showNotes() }
    private func showTrash() { sceneModel?.showTrash() }
    private func showList() { sceneModel?.showList() }
    private func showGrid() { sceneModel?.showGrid() }
    private func togglePin() { sceneModel?.togglePin() }
    private func moveToTrash() { sceneModel?.moveToTrash() }
    private func restore() { sceneModel?.restore() }
    private func requestPermanentDeletion() { sceneModel?.requestPermanentDeletion() }
    private func toggleBold() { editorController?.apply(.bold) }
    private func toggleItalic() { editorController?.apply(.italic) }
    private func toggleUnderline() { editorController?.apply(.underline) }
    private func toggleStrikethrough() { editorController?.apply(.strikethrough) }
    private func toggleBulletedList() { editorController?.apply(.bulletList) }
    private func applyHeading(_ level: Int) { editorController?.apply(.heading(level)) }
    private func addImage() { detailActions?.addImage() }
    private func addTag() { detailActions?.addTag() }

    private var searchCommandTitle: LocalizedStringKey {
        "Search Notes…"
    }
}
