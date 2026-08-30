import NotejotCore
import SwiftUI
#if canImport(AppKit)
import AppKit
private typealias PlatformImage = NSImage
#elseif canImport(UIKit)
import UIKit
private typealias PlatformImage = UIImage
#endif

actor DataURLImageDecoder {
    static let shared = DataURLImageDecoder()

    func data(for source: String) -> Data? {
        ImageDataURL.decodedData(from: source)
    }
}

struct DataURLImage: View {
    let source: String
    let accessibilityLabel: String

    @State private var image: PlatformImage?

    var body: some View {
        Group {
            if let image {
#if canImport(AppKit)
                Image(nsImage: image)
                    .resizable()
                    .accessibilityLabel(accessibilityLabel)
#elseif canImport(UIKit)
                Image(uiImage: image)
                    .resizable()
                    .accessibilityLabel(accessibilityLabel)
#endif
            } else {
                Color.clear
                    .accessibilityHidden(true)
            }
        }
        .task(id: source) {
            let data = await DataURLImageDecoder.shared.data(for: source)
            guard !Task.isCancelled else { return }
            image = data.flatMap(PlatformImage.init(data:))
        }
    }
}
