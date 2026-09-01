import Foundation

public struct TagFacet: Identifiable, Hashable, Sendable {
    public struct ID: Hashable, Sendable {
        fileprivate let normalizedName: String
        fileprivate let normalizedColor: String

        public init(name: String, color: String) {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            normalizedName = trimmedName
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            normalizedColor = color.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        }
    }

    public let id: ID
    public let tag: Tag
    public let count: Int

    public var name: String { tag.name }
    public var color: String { tag.color }

    public init(tag: Tag, count: Int) {
        id = tag.facetID
        self.tag = tag
        self.count = count
    }

    public static func available(
        in notes: [Note],
        destination: Destination
    ) -> [TagFacet] {
        available(in: notes, destination: Optional(destination))
    }

    public static func available(in notes: [Note]) -> [TagFacet] {
        available(in: notes, destination: nil)
    }

    private static func available(
        in notes: [Note],
        destination: Destination?
    ) -> [TagFacet] {
        var representatives: [ID: Tag] = [:]
        var counts: [ID: Int] = [:]

        for note in notes {
            guard includes(note, for: destination) else { continue }
            addFacets(from: note, representatives: &representatives, counts: &counts)
        }

        return makeFacets(representatives: representatives, counts: counts)
    }

    private static func includes(_ note: Note, for destination: Destination?) -> Bool {
        guard let destination else { return true }
        return destination == .trash ? note.isTrashed : !note.isTrashed
    }

    private static func addFacets(
        from note: Note,
        representatives: inout [ID: Tag],
        counts: inout [ID: Int]
    ) {
        var noteFacetIDs: Set<ID> = []
        for tag in note.tags {
            let id = tag.facetID
            if representatives[id] == nil { representatives[id] = tag }
            if noteFacetIDs.insert(id).inserted { counts[id, default: 0] += 1 }
        }
    }

    private static func makeFacets(
        representatives: [ID: Tag],
        counts: [ID: Int]
    ) -> [TagFacet] {
        representatives.compactMap { id, tag in
            guard let count = counts[id] else { return nil }
            return TagFacet(tag: tag, count: count)
        }
        .sorted(by: facetSort)
    }

    private static func facetSort(_ lhs: TagFacet, _ rhs: TagFacet) -> Bool {
        let nameOrder = lhs.name.localizedStandardCompare(rhs.name)
        if nameOrder != .orderedSame { return nameOrder == .orderedAscending }
        return lhs.color.localizedStandardCompare(rhs.color) == .orderedAscending
    }
}
