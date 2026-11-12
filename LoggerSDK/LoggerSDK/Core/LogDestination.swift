import Foundation

public protocol LogDestination: Sendable {
    var identifier: String { get }
    var minimumLevel: LogLevel { get }

    func write(_ event: LogEvent) async throws
    func writeBatch(_ events: [LogEvent]) async throws
    func flush() async throws
}

extension LogDestination {
    public func writeBatch(_ events: [LogEvent]) async throws {
        for event in events {
            try await write(event)
        }
    }
}
