import Foundation
import ImageIO
import NotejotCore
import UniformTypeIdentifiers

struct ImageImportResult: Sendable {
    let dataURLs: [String]
    let failedCount: Int
}

actor ImageImporter {
    static let shared = ImageImporter()

    private let maximumOriginalByteCount = 400_000
    private let maximumPixelDimension = 1_600
    private let jpegQuality = 0.85

    func importImages(from urls: [URL], limit: Int) -> ImageImportResult {
        var dataURLs: [String] = []
        var failedCount = 0

        for url in urls.prefix(max(0, limit)) {
            do {
                dataURLs.append(try importImage(from: url))
            } catch {
                failedCount += 1
            }
        }

        return ImageImportResult(dataURLs: dataURLs, failedCount: failedCount)
    }

    private func importImage(from url: URL) throws -> String {
        let isScoped = url.startAccessingSecurityScopedResource()
        defer {
            if isScoped { url.stopAccessingSecurityScopedResource() }
        }

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let typeIdentifier = CGImageSourceGetType(source) as String?,
              let sourceType = UTType(typeIdentifier),
              let sourceMIME = sourceType.preferredMIMEType,
              ImageDataURL.allowedMIMETypes.contains(sourceMIME) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let pixelWidth = properties?[kCGImagePropertyPixelWidth] as? Int ?? .max
        let pixelHeight = properties?[kCGImagePropertyPixelHeight] as? Int ?? .max
        let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey])
        let fileSize = resourceValues?.fileSize ?? .max
        if fileSize <= maximumOriginalByteCount,
           pixelWidth <= maximumPixelDimension,
           pixelHeight <= maximumPixelDimension {
            let original = try Data(contentsOf: url, options: .mappedIfSafe)
            return dataURL(mimeType: sourceMIME, data: original)
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumPixelDimension,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let destinationType: UTType = sourceType.conforms(to: .png) ? .png : .jpeg
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output,
            destinationType.identifier as CFString,
            1,
            nil
        ) else {
            throw CocoaError(.fileWriteUnknown)
        }

        let destinationProperties: [CFString: Any] = destinationType == .jpeg
            ? [kCGImageDestinationLossyCompressionQuality: jpegQuality]
            : [:]
        CGImageDestinationAddImage(destination, image, destinationProperties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw CocoaError(.fileWriteUnknown)
        }

        guard let mimeType = destinationType.preferredMIMEType else {
            throw CocoaError(.fileWriteUnknown)
        }
        return dataURL(mimeType: mimeType, data: output as Data)
    }

    private func dataURL(mimeType: String, data: Data) -> String {
        "data:\(mimeType);base64,\(data.base64EncodedString())"
    }
}
