import XCTest
@testable import LoggerSDK

final class UploadManagerTests: XCTestCase {
    func testSuccessfulUploadMarksEventsUploaded() async throws {
        let event = LogEvent.fixture()
        let storage = InMemoryLogStorage()
        try await storage.append(event)

        let api = MockAPIClient(result: .success(acceptedIDs: [event.id]))
        let manager = UploadManager(
            storage: storage,
            apiClient: api,
            configuration: .init(batchSize: 10, flushInterval: 60)
        )

        try await manager.flushNow()

        let pending = try await storage.fetchPending(limit: 100)
        XCTAssertTrue(pending.isEmpty)
        XCTAssertEqual(api.uploadCount, 1)
    }

    func testEnqueueTriggersFlushAtBatchSize() async throws {
        let storage = InMemoryLogStorage()
        let events = (0..<3).map { _ in LogEvent.fixture(message: UUID().uuidString) }
        let api = MockAPIClient(result: .success(acceptedIDs: events.map(\.id)))

        let manager = UploadManager(
            storage: storage,
            apiClient: api,
            configuration: .init(batchSize: 3, flushInterval: 60)
        )

        for event in events {
            try await manager.enqueue(event)
        }

        let pending = try await storage.fetchPending(limit: 10)
        XCTAssertTrue(pending.isEmpty)
        XCTAssertEqual(api.uploadCount, 1)
    }
}
