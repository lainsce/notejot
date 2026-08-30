import Foundation

public struct TaskItem: Identifiable, Codable, Equatable, Hashable, Sendable {
    public var id: String
    public var text: String
    public var isCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case id, text
        case isCompleted = "is_completed"
    }

    public init(
        id: String = TaskItem.newID(),
        text: String = "",
        isCompleted: Bool = false
    ) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? Self.newID()
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
    }

    public static func newID() -> String {
        "t" + UUID().uuidString.replacing("-", with: "").lowercased()
    }
}
