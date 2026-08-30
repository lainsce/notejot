public enum NoteFilter {
    public static func matching(
        _ notes: [Note],
        destination: Destination,
        query: String,
        tag: TagFacet.ID? = nil
    ) -> [Note] {
        var result = notes.filter { destination == .trash ? $0.isTrashed : !$0.isTrashed }
        if let tag {
            result = result.filter { note in
                note.tags.contains { $0.facetID == tag }
            }
        }
        guard !query.isEmpty else { return result }
        return result.filter {
            $0.title.localizedStandardContains(query) ||
            $0.content.localizedStandardContains(query)
        }
    }
}
