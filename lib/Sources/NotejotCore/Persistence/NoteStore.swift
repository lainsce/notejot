import Foundation
import Observation

@MainActor
@Observable
public final class NoteStore {
    public static let maxImages = 4

    public private(set) var notes: [Note] = []
    public private(set) var taskCategories: [TaskCategory] = []
    public private(set) var lastSaveError: String?
    public private(set) var isLoaded = false

    private let persistence: NotePersistence
    private var saveGeneration = 0
    private var completedSaveGeneration = 0
    private var latestSaveTask: Task<Void, Never>?

    public init(directory: URL) {
        persistence = NotePersistence(directory: directory)
    }

    public static func defaultDirectory() -> URL {
        URL.applicationSupportDirectory.appending(
            path: "notejot",
            directoryHint: .isDirectory
        )
    }

    public var hasPendingSave: Bool {
        completedSaveGeneration < saveGeneration
    }

    public func load() async {
        guard !isLoaded else { return }
        let result = await persistence.load()
        if var file = result.file {
            for index in file.notes.indices {
                file.notes[index].images = Self.sanitizeImages(file.notes[index].images)
            }
            notes = file.notes
            taskCategories = file.taskCategories
            resort()
        }
        lastSaveError = result.errorMessage
        isLoaded = true
    }

    public func flush() async {
        await latestSaveTask?.value
    }

    static func applicationDirectory(
        in applicationSupportDirectory: URL,
        fileManager: FileManager = .default
    ) -> URL {
        let directory = applicationSupportDirectory.appending(
            path: "notejot",
            directoryHint: .isDirectory
        )
        let legacyDirectory = applicationSupportDirectory.appending(
            path: "minnote",
            directoryHint: .isDirectory
        )

        guard !fileManager.fileExists(atPath: directory.path),
              fileManager.fileExists(atPath: legacyDirectory.path) else {
            return directory
        }

        do {
            try fileManager.moveItem(at: legacyDirectory, to: directory)
            return directory
        } catch {
            // Continue using the legacy location if migration is unavailable so
            // a branding change can never make existing notes appear missing.
            return legacyDirectory
        }
    }

    public static func sanitizeImages(_ images: [String]) -> [String] {
        Array(images.lazy.filter(ImageDataURL.isValid).prefix(maxImages))
    }

    @discardableResult
    public func createNote() -> Note {
        let note = Note()
        notes.insert(note, at: 0)
        save()
        return note
    }

    // Pinning is not an edit — do not bump updatedAt or the note shuffles to
    // the top of the unpinned ordering when unpinned later.
    public func setPinned(id: Note.ID, pinned: Bool) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[index].isPinned = pinned
        resort()
        save()
    }

    public func setTags(id: Note.ID, tags: [Tag]) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[index].tags = tags
        notes[index].updatedAt = Note.now()
        resort()
        save()
    }

    // Two branches: soft-delete a live note; permanently remove an already-trashed one.
    public func trashNote(id: Note.ID) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        if notes[index].isTrashed {
            notes.remove(at: index)
        } else {
            notes[index].isTrashed = true
            notes[index].isPinned = false
            notes[index].updatedAt = Note.now()
        }
        save()
    }

    public func restoreNote(id: Note.ID) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[index].isTrashed = false
        notes[index].updatedAt = Note.now()
        resort()
        save()
    }

    public func updateNoteContent(id: Note.ID, title: String, content: String) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[index].title = title
        notes[index].content = content
        notes[index].updatedAt = Note.now()
        resort()
        save()
    }

    public func updateImages(id: Note.ID, images: [String]) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[index].images = Self.sanitizeImages(images)
        notes[index].updatedAt = Note.now()
        resort()
        save()
    }

    public func appendImages(id: Note.ID, images: [String]) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[index].images = Self.sanitizeImages(notes[index].images + images)
        notes[index].updatedAt = Note.now()
        resort()
        save()
    }

    @discardableResult
    public func createTaskCategory() -> TaskCategory {
        let category = TaskCategory()
        taskCategories.insert(category, at: 0)
        save()
        return category
    }

    public func updateTaskCategoryTitle(id: TaskCategory.ID, title: String) {
        guard let index = taskCategories.firstIndex(where: { $0.id == id }) else { return }
        taskCategories[index].title = title
        taskCategories[index].updatedAt = Note.now()
        save()
    }

    public func updateTaskCategoryColor(id: TaskCategory.ID, color: String) {
        guard let index = taskCategories.firstIndex(where: { $0.id == id }),
              taskCategories[index].color != color else { return }
        taskCategories[index].color = color
        taskCategories[index].updatedAt = Note.now()
        save()
    }

    @discardableResult
    public func addTaskItem(categoryID: TaskCategory.ID, text: String) -> TaskItem? {
        guard let index = taskCategories.firstIndex(where: { $0.id == categoryID }) else { return nil }
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return nil }

        let item = TaskItem(text: trimmedText)
        taskCategories[index].items.append(item)
        taskCategories[index].updatedAt = Note.now()
        save()
        return item
    }

    public func updateTaskItem(
        categoryID: TaskCategory.ID,
        itemID: TaskItem.ID,
        text: String
    ) {
        guard let categoryIndex = taskCategories.firstIndex(where: { $0.id == categoryID }),
              let itemIndex = taskCategories[categoryIndex].items.firstIndex(where: { $0.id == itemID }) else {
            return
        }

        taskCategories[categoryIndex].items[itemIndex].text = text
        taskCategories[categoryIndex].updatedAt = Note.now()
        save()
    }

    public func setTaskItemCompleted(
        categoryID: TaskCategory.ID,
        itemID: TaskItem.ID,
        completed: Bool
    ) {
        guard let categoryIndex = taskCategories.firstIndex(where: { $0.id == categoryID }),
              let itemIndex = taskCategories[categoryIndex].items.firstIndex(where: { $0.id == itemID }) else {
            return
        }

        taskCategories[categoryIndex].items[itemIndex].isCompleted = completed
        taskCategories[categoryIndex].updatedAt = Note.now()
        save()
    }

    public func removeTaskItem(categoryID: TaskCategory.ID, itemID: TaskItem.ID) {
        guard let categoryIndex = taskCategories.firstIndex(where: { $0.id == categoryID }) else { return }
        taskCategories[categoryIndex].items.removeAll { $0.id == itemID }
        taskCategories[categoryIndex].updatedAt = Note.now()
        save()
    }

    public func setAllTaskItemsCompleted(categoryID: TaskCategory.ID, completed: Bool) {
        guard let categoryIndex = taskCategories.firstIndex(where: { $0.id == categoryID }),
              taskCategories[categoryIndex].items.contains(where: { $0.isCompleted != completed }) else {
            return
        }

        for itemIndex in taskCategories[categoryIndex].items.indices {
            taskCategories[categoryIndex].items[itemIndex].isCompleted = completed
        }
        taskCategories[categoryIndex].updatedAt = Note.now()
        save()
    }

    public func clearCompletedTaskItems(categoryID: TaskCategory.ID) {
        guard let categoryIndex = taskCategories.firstIndex(where: { $0.id == categoryID }),
              taskCategories[categoryIndex].items.contains(where: \.isCompleted) else { return }
        taskCategories[categoryIndex].items.removeAll(where: \.isCompleted)
        taskCategories[categoryIndex].updatedAt = Note.now()
        save()
    }

    public func deleteTaskCategory(id: TaskCategory.ID) {
        taskCategories.removeAll { $0.id == id }
        save()
    }

    public func reportError(_ message: LocalizedStringResource) {
        lastSaveError = String(localized: message)
    }

    public func acknowledgeSaveError() {
        lastSaveError = nil
    }

    public func seedWelcomeNoteIfEmpty() {
        guard !notes.contains(where: { !$0.isTrashed }) else { return }
        let welcomeBody = String(
            localized: "Start writing your notes here. Use New Note to create a note, the tag button to organize it, and All Notes or Trash in Destinations.",
            bundle: #bundle,
            comment: "Body of the welcome note created for a new user."
        )
        let welcome = Note(
            title: String(
                localized: "Welcome to Notejot",
                bundle: #bundle,
                comment: "Title of the welcome note created for a new user."
            ),
            content: "<p>\(HTMLMapper.escape(welcomeBody))</p>"
        )
        notes.insert(welcome, at: 0)
        save()
    }

    private func save() {
        saveGeneration += 1
        let generation = saveGeneration
        let snapshot = NoteFile(notes: notes, taskCategories: taskCategories)
        latestSaveTask = Task { [persistence] in
            let errorMessage = await persistence.save(snapshot, generation: generation)
            completedSaveGeneration = max(completedSaveGeneration, generation)
            if generation == saveGeneration, let errorMessage {
                lastSaveError = errorMessage
            }
        }
    }

    // Pinned notes float to the top; within each group RFC3339 timestamps sort descending.
    private func resort() {
        notes.sort {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            return $0.updatedAt > $1.updatedAt
        }
    }
}
