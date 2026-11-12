import Foundation
@testable import LoggerSDK

actor InMemoryLogStorage: LogStorage {
    private var events: [LogEvent] = []
    private var uploadedIDs: Set<UUID> = []

    func append(_ event: LogEvent) async throws {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        } else {
            events.append(event)
        }
    }

    func fetchPending(limit: Int) async throws -> [LogEvent] {
        Array(
            events
                .filter { !uploadedIDs.contains($0.id) }
                .sorted { $0.timestamp < $1.timestamp }
                .prefix(max(1, limit))
        )
    }

    func markUploaded(ids: [UUID]) async throws {
        uploadedIDs.formUnion(ids)
    }

    func delete(olderThan date: Date) async throws {
        events.removeAll { $0.timestamp < date }
    }

    func count() async throws -> Int {
        events.count
    }

    func pendingCount() async throws -> Int {
        events.filter { !uploadedIDs.contains($0.id) }.count
    }

    func flush() async throws {}
}

final class MockAPIClient: APIClient, @unchecked Sendable {
    enum Result {
        case success(acceptedIDs: [UUID])
        case failure(Error)
    }

    private let result: Result
    private(set) var uploadCount = 0
    private let lock = NSLock()

    init(result: Result) {
        self.result = result
    }

    func upload(logs: [LogEvent]) async throws -> UploadResponse {
        lock.withLock { uploadCount += 1 }

        switch result {
        case .success(let acceptedIDs):
            return UploadResponse(acceptedIDs: acceptedIDs)
        case .failure(let error):
            throw error
        }
    }
}

final class MockLogDestination: LogDestination, @unchecked Sendable {
    let identifier: String
    var minimumLevel: LogLevel
    private let lock = NSLock()
    private var _events: [LogEvent] = []

    var events: [LogEvent] {
        lock.withLock { _events }
    }

    init(identifier: String = "mock", minimumLevel: LogLevel = .trace) {
        self.identifier = identifier
        self.minimumLevel = minimumLevel
    }

    func write(_ event: LogEvent) async throws {
        lock.withLock { _events.append(event) }
    }

    func flush() async throws {}
}

extension LogEvent {
    static func fixture(
        level: LogLevel = .info,
        message: String = "test message"
    ) -> LogEvent {
        LogEvent.make(
            level: level,
            message: message,
            sessionID: "test-session",
            userID: nil
        )
    }
}
