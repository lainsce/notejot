import AppIntents
import Foundation
import SwiftUI
import WidgetKit

nonisolated private enum NotejotWidgetConstants {
    static let kind = "NotejotSingleNoteWidget"
    static let fileName = "notejot-widget.json"
    static let defaultsKey = "notejot.widget.snapshot"

    static var appGroupIdentifier: String {
#if os(macOS)
        "GXLP3297S8.com.github.lainsce.Notejot"
#else
        "group.com.github.lainsce.Notejot"
#endif
    }
}

nonisolated struct NotejotWidgetRecord: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let excerpt: String
    let updatedAt: String
}

nonisolated struct NotejotWidgetSnapshot: Codable, Sendable {
    let notes: [NotejotWidgetRecord]

    nonisolated static func load() -> NotejotWidgetSnapshot {
        let data: Data?
        if let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: NotejotWidgetConstants.appGroupIdentifier
        ) {
            data = try? Data(
                contentsOf: container.appendingPathComponent(NotejotWidgetConstants.fileName)
            )
        } else {
            data = UserDefaults(suiteName: NotejotWidgetConstants.appGroupIdentifier)?
                .data(forKey: NotejotWidgetConstants.defaultsKey)
        }
        guard let data, let snapshot = try? JSONDecoder().decode(Self.self, from: data) else {
            return Self(notes: [])
        }
        return snapshot
    }
}

struct NotejotWidgetNoteEntity: AppEntity, Hashable {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Note")
    static let defaultQuery = NotejotWidgetNoteQuery()

    let id: String
    let title: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: .init(stringLiteral: title.isEmpty ? "Untitled note" : title))
    }
}

struct NotejotWidgetNoteQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [NotejotWidgetNoteEntity] {
        let records = NotejotWidgetSnapshot.load().notes
        return identifiers.compactMap { id in
            guard let record = records.first(where: { $0.id == id }) else { return nil }
            return NotejotWidgetNoteEntity(id: record.id, title: record.title)
        }
    }

    func suggestedEntities() async throws -> [NotejotWidgetNoteEntity] {
        NotejotWidgetSnapshot.load().notes.map {
            NotejotWidgetNoteEntity(id: $0.id, title: $0.title)
        }
    }
}

struct SelectNoteIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Single Note"
    static let description = IntentDescription("Choose which Notejot note the widget shows.")

    @Parameter(title: "Note")
    var note: NotejotWidgetNoteEntity?

    init() {}
}

struct NotejotWidgetEntry: TimelineEntry {
    let date: Date
    let record: NotejotWidgetRecord?
}

struct NotejotSingleNoteProvider: AppIntentTimelineProvider {
    func placeholder(in _: Context) -> NotejotWidgetEntry {
        NotejotWidgetEntry(
            date: .now,
            record: NotejotWidgetRecord(
                id: "placeholder",
                title: "A note worth keeping",
                excerpt: "Your latest note will appear here.",
                updatedAt: ""
            )
        )
    }

    func snapshot(for configuration: SelectNoteIntent, in _: Context) async -> NotejotWidgetEntry {
        entry(for: configuration)
    }

    func timeline(for configuration: SelectNoteIntent, in _: Context) async -> Timeline<NotejotWidgetEntry> {
        let entry = entry(for: configuration)
        let refresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now)
            ?? .now.addingTimeInterval(1_800)
        return Timeline(entries: [entry], policy: .after(refresh))
    }

    private func entry(for configuration: SelectNoteIntent) -> NotejotWidgetEntry {
        let records = NotejotWidgetSnapshot.load().notes
        let selectedID = configuration.note?.id
        let record = records.first(where: { $0.id == selectedID }) ?? records.first
        return NotejotWidgetEntry(date: .now, record: record)
    }
}

struct NotejotSingleNoteWidgetEntryView: View {
    let entry: NotejotWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let record = entry.record {
                VStack(alignment: .leading, spacing: 8) {
                    Text(record.title.isEmpty ? "Untitled note" : record.title)
                        .font(.system(size: family == .systemSmall ? 18 : 20, design: .serif))
                        .lineLimit(family == .systemSmall ? 2 : 1)
                        .minimumScaleFactor(0.76)
                    Text(record.excerpt.isEmpty ? "No text yet" : record.excerpt)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(family == .systemSmall ? 5 : 4)
                        .minimumScaleFactor(0.82)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .widgetURL(URL(string: "notejot://note/\(record.id)"))
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.title2)
                    Text("Open Notejot to add a note")
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .widgetURL(URL(string: "notejot://new"))
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

struct NotejotSingleNoteWidget: Widget {
    let kind = NotejotWidgetConstants.kind

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectNoteIntent.self,
            provider: NotejotSingleNoteProvider()
        ) { entry in
            NotejotSingleNoteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Single Note")
        .description("Keep one Notejot note visible at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct NotejotWidgetBundle: WidgetBundle {
    var body: some Widget {
        NotejotSingleNoteWidget()
    }
}
