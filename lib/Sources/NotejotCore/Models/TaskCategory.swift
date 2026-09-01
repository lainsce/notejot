import Foundation

public struct TaskCategory: Identifiable, Codable, Equatable, Hashable, Sendable {
    public static let defaultColor = "#4A90D9"

    public var id: String
    public var title: String
    public var color: String
    public var items: [TaskItem]
    public var createdAt: String
    public var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, title, color, items
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: String = TaskCategory.newID(),
        title: String = "",
        color: String = TaskCategory.defaultColor,
        items: [TaskItem] = [],
        createdAt: String = Note.now(),
        updatedAt: String = Note.now()
    ) {
        self.id = id
        self.title = title
        self.color = color
        self.items = items
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try Self.decode(container, String.self, forKey: .id, default: Self.newID())
        title = try Self.decode(container, String.self, forKey: .title, default: "")
        color = try Self.decode(container, String.self, forKey: .color, default: Self.defaultColor)
        items = try Self.decode(container, [TaskItem].self, forKey: .items, default: [])
        let fallbackTimestamp = Note.now()
        createdAt = try Self.decode(container, String.self, forKey: .createdAt, default: fallbackTimestamp)
        updatedAt = try Self.decode(container, String.self, forKey: .updatedAt, default: createdAt)
    }

    private static func decode<T: Decodable>(
        _ container: KeyedDecodingContainer<CodingKeys>,
        _ type: T.Type,
        forKey key: CodingKeys,
        default fallback: @autoclosure () -> T
    ) throws -> T {
        try container.decodeIfPresent(type, forKey: key) ?? fallback()
    }

    public static func newID() -> String {
        "c" + UUID().uuidString.replacing("-", with: "").lowercased()
    }
}
