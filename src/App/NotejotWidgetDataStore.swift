import Foundation
import NotejotCore
import WidgetKit

/// Publishes a small, privacy-preserving note snapshot for the Notejot widget.
///
/// The widget cannot read the app's sandboxed Application Support directory directly, so the
/// app writes only the fields needed for the widget into its App Group container. The complete
/// note body and image payloads never leave the app's normal store.
@MainActor
enum NotejotWidgetDataStore {
    static let kind = "NotejotSingleNoteWidget"

    private static let macOSAppGroup = "GXLP3297S8.com.github.lainsce.Notejot"
    private static let iOSAppGroup = "group.com.github.lainsce.Notejot"
    private static let fileName = "notejot-widget.json"
    private static let defaultsKey = "notejot.widget.snapshot"

    private struct Snapshot: Codable, Sendable {
        let notes: [Record]
    }

    private struct Record: Codable, Sendable {
        let id: String
        let title: String
        let excerpt: String
        let updatedAt: String
    }

    static func save(notes: [Note]) {
        let records = notes
            .filter { !$0.isTrashed }
            .prefix(24)
            .map { note in
                Record(
                    id: note.id,
                    title: note.title.trimmingCharacters(in: .whitespacesAndNewlines),
                    excerpt: excerpt(from: note.content),
                    updatedAt: note.updatedAt
                )
            }
        let snapshot = Snapshot(notes: Array(records))
        guard let data = try? JSONEncoder().encode(snapshot) else { return }

        if let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) {
            let url = container.appendingPathComponent(fileName, isDirectory: false)
            try? data.write(to: url, options: .atomic)
        }
        UserDefaults(suiteName: appGroupIdentifier)?.set(data, forKey: defaultsKey)
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }

    private static var appGroupIdentifier: String {
#if os(macOS)
        macOSAppGroup
#else
        iOSAppGroup
#endif
    }

    private static func excerpt(from html: String) -> String {
        var plain = html
        var scan = plain.startIndex
        while let open = plain.range(of: "<", range: scan..<plain.endIndex),
              let close = plain.range(of: ">", range: open.upperBound..<plain.endIndex) {
            plain.removeSubrange(open.lowerBound..<close.upperBound)
            scan = open.lowerBound
        }
        plain = plain
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
        let words = plain
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        let compact = words.joined(separator: " ")
        guard compact.count > 180 else { return compact }
        let end = compact.index(compact.startIndex, offsetBy: 177)
        return String(compact[..<end]) + "…"
    }
}
