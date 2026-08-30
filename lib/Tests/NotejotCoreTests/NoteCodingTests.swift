import Foundation
import Testing
@testable import NotejotCore

@Test func legacyFixtureDecodesWithoutLosingDefaults() throws {
    let data = try Data(contentsOf: legacyFixtureURL())
    let note = try JSONDecoder().decode(NoteFile.self, from: data).notes[0]

    #expect(note.id == "n1a2b3c4d5e6f708192a3b4c5d6e7f809")
    #expect(note.createdAt == "2026-01-01T00:00:00.123456789Z")
    #expect(note.updatedAt == "2026-01-02T12:30:00.987654321Z")
    #expect(note.isPinned == false)
    #expect(note.images.isEmpty)
    #expect(try JSONDecoder().decode(NoteFile.self, from: data).taskCategories.isEmpty)
}

@Test func taskCategoryRoundTripPreservesItemsAndCompletion() throws {
    let category = TaskCategory(
        id: "c1",
        title: "Launch",
        color: "#B86582",
        items: [TaskItem(id: "t1", text: "Ship Notejot", isCompleted: true)],
        createdAt: "2026-08-03T00:00:00.000Z",
        updatedAt: "2026-08-03T01:00:00.000Z"
    )
    let original = NoteFile(notes: [], taskCategories: [category])

    let decoded = try JSONDecoder().decode(
        NoteFile.self,
        from: JSONEncoder().encode(original)
    )

    #expect(decoded == original)
    #expect(decoded.taskCategories[0].color == "#B86582")
    #expect(decoded.taskCategories[0].items[0].isCompleted)
}

@Test func legacyTaskCategoryDefaultsToTheCustomBlue() throws {
    let data = Data(
        #"{"id":"c1","title":"Legacy","items":[],"created_at":"now","updated_at":"now"}"#.utf8
    )

    let decoded = try JSONDecoder().decode(TaskCategory.self, from: data)

    #expect(decoded.color == TaskCategory.defaultColor)
}

@Test func legacyFixtureRoundTripPreservesOpaqueTimestamps() throws {
    let original = try JSONDecoder().decode(
        NoteFile.self,
        from: Data(contentsOf: legacyFixtureURL())
    )
    let encoded = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(NoteFile.self, from: encoded)

    #expect(decoded.notes[0].createdAt == original.notes[0].createdAt)
    #expect(decoded.notes[0].updatedAt == original.notes[0].updatedAt)
}
