import XCTest
@testable import LoggerSDK

final class FileStorageTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
    }

    func testAppendAndCount() async throws {
        let storage = try FileStorage(configuration: .init(directory: directory))
        try await storage.append(LogEvent.fixture(message: "first"))
        try await storage.append(LogEvent.fixture(message: "second"))

        let count = try await storage.count()
        XCTAssertEqual(count, 2)
    }
}
