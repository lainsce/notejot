public enum NoteFilter {
    public static func matching(
        _ notes: [Note],
        destination: Destination,
        query: String,
        tag: TagFacet.ID? = nil
    ) -> [Note] {
        var result = notes.filter { matchesDestination($0, destination: destination) }
        if let tag {
            result = result.filter { note in hasTag(note, matching: tag) }
        }
        guard !query.isEmpty else { return result }
        return result.filter { matchesQuery($0, query: query) }
    }

    private static func matchesDestination(_ note: Note, destination: Destination) -> Bool {
        destination == .trash ? note.isTrashed : !note.isTrashed
    }

    private static func hasTag(_ note: Note, matching tag: TagFacet.ID) -> Bool {
        note.tags.contains { $0.facetID == tag }
    }

    private static func matchesQuery(_ note: Note, query: String) -> Bool {
        note.title.localizedStandardContains(query) || note.content.localizedStandardContains(query)
    }
}
