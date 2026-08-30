import Foundation

public enum ImageDataURL {
    public static let allowedMIMETypes: Set<String> = [
        "image/png", "image/jpeg", "image/gif", "image/webp",
        "image/avif", "image/heic", "image/heif",
    ]

    public static func isValid(_ source: String) -> Bool {
        guard let components = components(from: source) else { return false }
        let payload = components.payload
        guard !payload.isEmpty, payload.count.isMultiple(of: 4) else { return false }

        let paddingCount = payload.reversed().prefix(while: { $0 == "=" }).count
        guard paddingCount <= 2 else { return false }
        let content = payload.dropLast(paddingCount)
        guard !content.contains("=") else { return false }

        return content.utf8.allSatisfy { byte in
            byte >= 65 && byte <= 90 ||
            byte >= 97 && byte <= 122 ||
            byte >= 48 && byte <= 57 ||
            byte == 43 || byte == 47
        }
    }

    public static func decodedData(from source: String) -> Data? {
        guard isValid(source), let components = components(from: source) else { return nil }
        return Data(base64Encoded: String(components.payload))
    }

    public static func mimeType(in source: String) -> String? {
        components(from: source)?.mimeType
    }

    private static func components(from source: String) -> (mimeType: String, payload: Substring)? {
        guard let separator = source.range(of: ";base64,") else { return nil }
        let header = source[..<separator.lowerBound]
        guard header.hasPrefix("data:") else { return nil }
        let mimeType = String(header.dropFirst("data:".count)).lowercased()
        guard allowedMIMETypes.contains(mimeType) else { return nil }
        return (mimeType, source[separator.upperBound...])
    }
}
