import Foundation

public struct Tag: Identifiable, Codable, Equatable, Hashable, Sendable {
    public var id: String
    public var color: String  // hex, e.g. "#4A90D9"
    public var name: String

    public init(id: String = Tag.newID(), color: String, name: String) {
        self.id = id
        self.color = color
        self.name = name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? Self.newID()
        color = try container.decodeIfPresent(String.self, forKey: .color) ?? "#4A90D9"
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Tag"
    }

    public static func newID() -> String {
        "t" + UUID().uuidString.replacing("-", with: "").lowercased()
    }

    public var facetID: TagFacet.ID {
        TagFacet.ID(name: name, color: color)
    }
}
