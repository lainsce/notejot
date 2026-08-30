import Foundation

public struct Note: Identifiable, Codable, Equatable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var content: String
    public var isPinned: Bool
    public var isTrashed: Bool
    /// Opaque RFC3339 values. Previous builds wrote nanosecond precision, so
    /// decoding these as `Date` would silently rewrite them on the next save.
    public var createdAt: String
    public var updatedAt: String
    public var tags: [Tag]
    public var images: [String]  // base64 data URLs, max 4

    // Maps Swift camelCase to Electron's snake_case JSON on disk.
    enum CodingKeys: String, CodingKey {
        case id, title, content, tags, images
        case isPinned  = "is_pinned"
        case isTrashed = "is_deleted"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: String = Note.newID(),
        title: String = "",
        content: String = "",
        isPinned: Bool = false,
        isTrashed: Bool = false,
        createdAt: String = Note.now(),
        updatedAt: String = Note.now(),
        tags: [Tag] = [],
        images: [String] = []
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.isPinned = isPinned
        self.isTrashed = isTrashed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tags = tags
        self.images = images
    }

    // Every field defaults so notes written by older builds still load.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id        = try c.decodeIfPresent(String.self,  forKey: .id)        ?? Self.newID()
        title     = try c.decodeIfPresent(String.self,  forKey: .title)     ?? ""
        content   = try c.decodeIfPresent(String.self,  forKey: .content)   ?? ""
        isPinned  = try c.decodeIfPresent(Bool.self,    forKey: .isPinned)  ?? false
        isTrashed = try c.decodeIfPresent(Bool.self,    forKey: .isTrashed) ?? false
        let fallbackTimestamp = Self.now()
        createdAt = try c.decodeIfPresent(String.self,  forKey: .createdAt) ?? fallbackTimestamp
        updatedAt = try c.decodeIfPresent(String.self,  forKey: .updatedAt) ?? createdAt
        tags      = try c.decodeIfPresent([Tag].self,   forKey: .tags)      ?? []
        images    = try c.decodeIfPresent([String].self, forKey: .images)   ?? []
    }

    public static func now() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: .now)
    }

    public static func newID() -> String {
        "n" + UUID().uuidString.replacing("-", with: "").lowercased()
    }
}

public struct NoteFile: Codable, Equatable, Sendable {
    public var notes: [Note]
    public var taskCategories: [TaskCategory]

    enum CodingKeys: String, CodingKey {
        case notes
        case taskCategories = "task_categories"
    }

    public init(notes: [Note], taskCategories: [TaskCategory] = []) {
        self.notes = notes
        self.taskCategories = taskCategories
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        notes = try container.decodeIfPresent([Note].self, forKey: .notes) ?? []
        taskCategories = try container.decodeIfPresent(
            [TaskCategory].self,
            forKey: .taskCategories
        ) ?? []
    }
}
