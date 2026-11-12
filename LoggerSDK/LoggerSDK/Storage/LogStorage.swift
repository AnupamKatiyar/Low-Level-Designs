import Foundation

public enum LogStorageError: Error, Sendable, Equatable {
    case encodingFailed
    case decodingFailed
    case fileOperationFailed(String)
    case databaseError(String)
}

public protocol LogStorage: Sendable {
    func append(_ event: LogEvent) async throws
    func append(_ events: [LogEvent]) async throws
    func fetchPending(limit: Int) async throws -> [LogEvent]
    func markUploaded(ids: [UUID]) async throws
    func delete(olderThan date: Date) async throws
    func count() async throws -> Int
    func pendingCount() async throws -> Int
    func flush() async throws
}

extension LogStorage {
    public func pendingCount() async throws -> Int {
        try await fetchPending(limit: Int.max).count
    }
}

extension LogStorage {
    public func append(_ events: [LogEvent]) async throws {
        for event in events {
            try await append(event)
        }
    }
}
