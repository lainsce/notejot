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
            if let destination,
               (destination == .trash ? !note.isTrashed : note.isTrashed) {
                continue
            }

            var noteFacetIDs: Set<ID> = []
            for tag in note.tags {
                let id = tag.facetID
                if representatives[id] == nil {
                    representatives[id] = tag
                }
                if noteFacetIDs.insert(id).inserted {
                    counts[id, default: 0] += 1
                }
            }
        }

        return representatives.compactMap { id, tag in
            guard let count = counts[id] else { return nil }
            return TagFacet(tag: tag, count: count)
        }
        .sorted {
            let nameOrder = $0.name.localizedStandardCompare($1.name)
            if nameOrder != .orderedSame { return nameOrder == .orderedAscending }
            return $0.color.localizedStandardCompare($1.color) == .orderedAscending
        }
    }
}
