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
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? Self.newID()
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        color = try container.decodeIfPresent(String.self, forKey: .color) ?? Self.defaultColor
        items = try container.decodeIfPresent([TaskItem].self, forKey: .items) ?? []
        let fallbackTimestamp = Note.now()
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? fallbackTimestamp
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? createdAt
    }

    public static func newID() -> String {
        "c" + UUID().uuidString.replacing("-", with: "").lowercased()
    }
}
