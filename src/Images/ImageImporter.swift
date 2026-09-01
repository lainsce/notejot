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
        defer { stopAccessIfNeeded(isScoped, url: url) }
        let source = try imageSource(from: url)
        let properties = sourceProperties(source)
        if fitsOriginal(url: url, properties: properties) {
            return dataURL(mimeType: source.mimeType, data: try Data(contentsOf: url, options: .mappedIfSafe))
        }
        return try compressedDataURL(source: source, properties: properties)
    }

    private struct ImageSourceInfo {
        let source: CGImageSource
        let type: UTType
        let mimeType: String
    }

    private func stopAccessIfNeeded(_ isScoped: Bool, url: URL) {
        if isScoped { url.stopAccessingSecurityScopedResource() }
    }

    private func imageSource(from url: URL) throws -> ImageSourceInfo {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let typeIdentifier = CGImageSourceGetType(source) as String?,
              let type = UTType(typeIdentifier),
              let mimeType = type.preferredMIMEType,
              ImageDataURL.allowedMIMETypes.contains(mimeType) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return ImageSourceInfo(source: source, type: type, mimeType: mimeType)
    }

    private func sourceProperties(_ source: ImageSourceInfo) -> [CFString: NSObject] {
        CGImageSourceCopyPropertiesAtIndex(source.source, 0, nil) as? [CFString: NSObject] ?? [:]
    }

    private func fitsOriginal(url: URL, properties: [CFString: NSObject]) -> Bool {
        let pixelWidth = imageDimension(kCGImagePropertyPixelWidth, in: properties)
        let pixelHeight = imageDimension(kCGImagePropertyPixelHeight, in: properties)
        let fileSize = sourceFileSize(url)
        return fitsDimensions(fileSize: fileSize, width: pixelWidth, height: pixelHeight)
    }

    private func imageDimension(_ key: CFString, in properties: [CFString: NSObject]) -> Int {
        (properties[key] as? NSNumber)?.intValue ?? .max
    }

    private func sourceFileSize(_ url: URL) -> Int {
        (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? .max
    }

    private func fitsDimensions(fileSize: Int, width: Int, height: Int) -> Bool {
        fileSize <= maximumOriginalByteCount
            && width <= maximumPixelDimension
            && height <= maximumPixelDimension
    }

    private func compressedDataURL(
        source: ImageSourceInfo,
        properties _: [CFString: NSObject]
    ) throws -> String {
        let image = try thumbnail(from: source.source)
        let destinationType: UTType = source.type.conforms(to: .png) ? .png : .jpeg
        let (mimeType, data) = try encodedThumbnail(image, type: destinationType)
        return dataURL(mimeType: mimeType, data: data)
    }

    private func thumbnail(from source: CGImageSource) throws -> CGImage {
        let options: [CFString: NSObject] = [
            kCGImageSourceCreateThumbnailFromImageAlways: NSNumber(value: true),
            kCGImageSourceCreateThumbnailWithTransform: NSNumber(value: true),
            kCGImageSourceThumbnailMaxPixelSize: NSNumber(value: maximumPixelDimension),
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return image
    }

    private func encodedThumbnail(_ image: CGImage, type: UTType) throws -> (String, Data) {
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, type.identifier as CFString, 1, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        CGImageDestinationAddImage(destination, image, destinationProperties(for: type) as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
        guard let mimeType = type.preferredMIMEType else { throw CocoaError(.fileWriteUnknown) }
        return (mimeType, output as Data)
    }

    private func destinationProperties(for type: UTType) -> [CFString: NSObject] {
        type == .jpeg ? [kCGImageDestinationLossyCompressionQuality: NSNumber(value: jpegQuality)] : [:]
    }

    private func dataURL(mimeType: String, data: Data) -> String {
        "data:\(mimeType);base64,\(data.base64EncodedString())"
    }
}
