import Foundation

func formattedNoteDate(_ timestamp: String) -> String {
    guard let date = parseNoteDate(timestamp) else { return timestamp }
    let calendar = Calendar.current
    if calendar.isDateInToday(date) {
        return date.formatted(date: .omitted, time: .shortened)
    }
    if calendar.isDateInYesterday(date) {
        return "Yesterday"
    }
    return date.formatted(date: .abbreviated, time: .omitted)
}

private func parseNoteDate(_ timestamp: String) -> Date? {
    if let parsed = try? Date(timestamp, strategy: .iso8601) {
        return parsed
    }
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.date(from: timestamp)
}
