import Foundation
import Testing
@testable import NotejotCore

@MainActor
@Test func storeLoadsAndResavesTheLegacyEnvelope() async throws {
    let directory = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let storeURL = directory.appending(path: "notes.json")
    try FileManager.default.copyItem(at: legacyFixtureURL(), to: storeURL)

    let store = NoteStore(directory: directory)
    await store.load()
    #expect(store.notes.count == 1)
    let timestamp = store.notes[0].updatedAt
    store.setPinned(id: store.notes[0].id, pinned: true)
    await store.flush()

    let saved = try JSONDecoder().decode(
        NoteFile.self,
        from: Data(contentsOf: storeURL)
    )
    #expect(saved.notes[0].updatedAt == timestamp)
    #expect(saved.notes[0].isPinned)
    #expect(saved.taskCategories.isEmpty)
}

@MainActor
@Test func taskCategoryEditsPersistThroughTheStore() async throws {
    let directory = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = NoteStore(directory: directory)
    await store.load()

    let category = store.createTaskCategory()
    store.updateTaskCategoryTitle(id: category.id, title: "Today")
    store.updateTaskCategoryColor(id: category.id, color: "#6B9B73")
    let item = try #require(store.addTaskItem(categoryID: category.id, text: "Write tests"))
    store.setTaskItemCompleted(categoryID: category.id, itemID: item.id, completed: true)
    await store.flush()

    let reloaded = NoteStore(directory: directory)
    await reloaded.load()
    let savedCategory = try #require(reloaded.taskCategories.first)
    #expect(savedCategory.title == "Today")
    #expect(savedCategory.color == "#6B9B73")
    #expect(savedCategory.items == [TaskItem(id: item.id, text: "Write tests", isCompleted: true)])
}

@MainActor
@Test func taskCategoryBulkCompletionActionsPersist() async throws {
    let directory = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = NoteStore(directory: directory)
    await store.load()
    let category = store.createTaskCategory()
    _ = store.addTaskItem(categoryID: category.id, text: "First")
    _ = store.addTaskItem(categoryID: category.id, text: "Second")

    store.setAllTaskItemsCompleted(categoryID: category.id, completed: true)
    #expect(store.taskCategories[0].items.allSatisfy { $0.isCompleted })

    store.clearCompletedTaskItems(categoryID: category.id)
    #expect(store.taskCategories[0].items.isEmpty)
    await store.flush()
    let reloaded = NoteStore(directory: directory)
    await reloaded.load()
    #expect(reloaded.taskCategories[0].items.isEmpty)
}

@MainActor
@Test func applicationDirectoryMigratesTheLegacyBrandDirectory() throws {
    let applicationSupportDirectory = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: applicationSupportDirectory) }

    let legacyDirectory = applicationSupportDirectory.appending(
        path: "minnote",
        directoryHint: .isDirectory
    )
    try FileManager.default.createDirectory(
        at: legacyDirectory,
        withIntermediateDirectories: true
    )
    let legacyStoreURL = legacyDirectory.appending(path: "notes.json")
    try Data("legacy notes".utf8).write(to: legacyStoreURL)

    let directory = NoteStore.applicationDirectory(in: applicationSupportDirectory)

    #expect(directory.lastPathComponent == "notejot")
    #expect(FileManager.default.fileExists(
        atPath: directory.appending(path: "notes.json").path
    ))
    #expect(!FileManager.default.fileExists(atPath: legacyDirectory.path))
}

@MainActor
@Test func applicationDirectoryPrefersAnExistingNotejotDirectory() throws {
    let applicationSupportDirectory = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: applicationSupportDirectory) }

    let directory = applicationSupportDirectory.appending(
        path: "notejot",
        directoryHint: .isDirectory
    )
    let legacyDirectory = applicationSupportDirectory.appending(
        path: "minnote",
        directoryHint: .isDirectory
    )
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: legacyDirectory, withIntermediateDirectories: true)

    let result = NoteStore.applicationDirectory(in: applicationSupportDirectory)

    #expect(result == directory)
    #expect(FileManager.default.fileExists(atPath: legacyDirectory.path))
}

@MainActor
@Test func corruptStoreIsQuarantinedBeforeAReplacementIsWritten() async throws {
    let directory = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let storeURL = directory.appending(path: "notes.json")
    try Data("{ not json".utf8).write(to: storeURL)

    let store = NoteStore(directory: directory)
    await store.load()

    #expect(store.notes.isEmpty)
    #expect(store.lastSaveError != nil)
    #expect(!FileManager.default.fileExists(atPath: storeURL.path))
    #expect(FileManager.default.fileExists(
        atPath: storeURL.appendingPathExtension("corrupt").path
    ))
}

@MainActor
@Test func imageRulesRejectExternalAndDocumentSources() {
    let valid = "data:image/png;base64,QUJDRA=="
    let sanitized = NoteStore.sanitizeImages([
        valid,
        "file:///tmp/photo.png",
        "https://example.com/photo.png",
        "data:image/svg+xml;base64,PHN2Zz4=",
    ])

    #expect(sanitized == [valid])
}

@MainActor
@Test func appendingImagesUsesTheCurrentStoreValueAndEnforcesTheLimit() async throws {
    let directory = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = NoteStore(directory: directory)
    await store.load()
    let note = store.createNote()
    let first = "data:image/png;base64,QUJDRA=="
    let second = "data:image/jpeg;base64,RUZHSA=="

    store.updateImages(id: note.id, images: [first])
    store.appendImages(id: note.id, images: Array(repeating: second, count: 5))
    await store.flush()

    #expect(store.notes.first(where: { $0.id == note.id })?.images.count == NoteStore.maxImages)
    #expect(store.notes.first(where: { $0.id == note.id })?.images.first == first)
}
