import XCTest
@testable import LoggerSDK

final class SQLiteStorageTests: XCTestCase {
    private var databaseURL: URL!

    override func setUpWithError() throws {
        databaseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("sqlite")
    }

    override func tearDownWithError() throws {
        if let databaseURL {
            try? FileManager.default.removeItem(at: databaseURL)
        }
    }

    func testPendingFetchAndMarkUploaded() async throws {
        let storage = try SQLiteStorage(configuration: .init(databaseURL: databaseURL))
        let first = LogEvent.fixture(message: "one")
        let second = LogEvent.fixture(message: "two")

        try await storage.append(first)
        try await storage.append(second)

        var pending = try await storage.fetchPending(limit: 10)
        XCTAssertEqual(pending.count, 2)

        try await storage.markUploaded(ids: [first.id])

        pending = try await storage.fetchPending(limit: 10)
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.id, second.id)
    }

    func testPendingCount() async throws {
        let storage = try SQLiteStorage(configuration: .init(databaseURL: databaseURL))
        let event = LogEvent.fixture()
        try await storage.append(event)

        let pendingBeforeUpload = try await storage.pendingCount()
        XCTAssertEqual(pendingBeforeUpload, 1)

        try await storage.markUploaded(ids: [event.id])
        let pendingAfterUpload = try await storage.pendingCount()
        XCTAssertEqual(pendingAfterUpload, 0)
    }
}
