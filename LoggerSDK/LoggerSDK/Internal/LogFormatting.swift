import Foundation

enum LogFormatting {
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func formatTimestamp(_ date: Date) -> String {
        iso8601Formatter.string(from: date)
    }

    static func formatConsoleLine(for event: LogEvent) -> String {
        let category = event.category.map { "[\($0)] " } ?? ""
        let metadata = event.metadata.isEmpty
            ? ""
            : " " + event.metadata.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: " ")
        return "\(formatTimestamp(event.timestamp)) \(event.level.label) \(category)\(event.message)\(metadata)"
    }
}
