import Testing
@testable import NotejotCore

@Test func searchUsesLocalizedUserFacingMatching() {
    let note = Note(title: "Résumé 10", content: "<p>Planning</p>")

    #expect(NoteFilter.matching([note], destination: .notes, query: "resume 10").count == 1)
    #expect(NoteFilter.matching([note], destination: .trash, query: "resume 10").isEmpty)
}

@Test func taskCategorySearchMatchesTitlesAndTaskText() {
    let work = TaskCategory(
        title: "Résumé",
        items: [TaskItem(text: "Send application")]
    )
    let personal = TaskCategory(
        title: "Personal",
        items: [TaskItem(text: "Buy coffee")]
    )

    #expect(TaskCategoryFilter.matching([work, personal], query: "resume") == [work])
    #expect(TaskCategoryFilter.matching([work, personal], query: "coffee") == [personal])
    #expect(TaskCategoryFilter.matching([work, personal], query: "").count == 2)
}

@Test func tagFacetsCombineEquivalentTagsAndCountNotesOnce() {
    let first = Tag(color: "#4A90D9", name: " Work ")
    let equivalent = Tag(color: "#4a90d9", name: "work")
    let anotherBlueTag = Tag(color: "#4A90D9", name: "Personal")
    let notes = [
        Note(title: "One", tags: [first, equivalent, anotherBlueTag]),
        Note(title: "Two", tags: [equivalent]),
        Note(title: "Deleted", isTrashed: true, tags: [first]),
    ]

    let facets = TagFacet.available(in: notes, destination: .notes)

    #expect(facets.count == 2)
    #expect(facets.first(where: { $0.id == first.facetID })?.count == 2)
    #expect(facets.first(where: { $0.id == anotherBlueTag.facetID })?.count == 1)
    #expect(TagFacet.available(in: notes).first(where: { $0.id == first.facetID })?.count == 3)
}

@Test func tagFilteringUsesNameAndColorAndComposesWithSearch() {
    let work = Tag(color: "#4A90D9", name: "Work")
    let personal = Tag(color: "#4A90D9", name: "Personal")
    let notes = [
        Note(title: "Roadmap", tags: [work]),
        Note(title: "Roadmap", tags: [personal]),
        Note(title: "Minutes", tags: [work]),
    ]

    let matches = NoteFilter.matching(
        notes,
        destination: .notes,
        query: "roadmap",
        tag: work.facetID
    )

    #expect(matches.map(\.title) == ["Roadmap"])
    #expect(matches[0].tags == [work])
}
