import Foundation

public enum ImageDataURL {
    public static let allowedMIMETypes: Set<String> = [
        "image/png", "image/jpeg", "image/gif", "image/webp",
        "image/avif", "image/heic", "image/heif",
    ]
    private static let base64Bytes: Set<UInt8> = Set(
        Array(65...90) + Array(97...122) + Array(48...57) + [43, 47]
    )

    public static func isValid(_ source: String) -> Bool {
        guard let components = components(from: source) else { return false }
        let payload = components.payload
        guard isValidPayload(payload) else { return false }
        let paddingCount = paddingCount(in: payload)
        return payload.dropLast(paddingCount).utf8.allSatisfy(isBase64Byte)
    }

    private static func isValidPayload(_ payload: Substring) -> Bool {
        guard !payload.isEmpty, payload.count.isMultiple(of: 4) else { return false }
        let paddingCount = paddingCount(in: payload)
        guard paddingCount <= 2 else { return false }
        let content = payload.dropLast(paddingCount)
        guard !content.contains("=") else { return false }
        return true
    }

    private static func paddingCount(in payload: Substring) -> Int {
        var count = 0
        for character in payload.reversed() {
            guard character == "=" else { break }
            count += 1
        }
        return count
    }

    private static func isBase64Byte(_ byte: UInt8) -> Bool {
        base64Bytes.contains(byte)
    }

    public static func decodedData(from source: String) -> Data? {
        guard isValid(source), let components = components(from: source) else { return nil }
        return Data(base64Encoded: String(components.payload))
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
