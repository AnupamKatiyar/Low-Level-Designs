import XCTest
@testable import LoggerSDK

final class LogEventTests: XCTestCase {
    func testCodableRoundTrip() throws {
        let event = LogEvent.fixture(level: .error, message: "failure")
        let data = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(LogEvent.self, from: data)

        XCTAssertEqual(decoded.id, event.id)
        XCTAssertEqual(decoded.level, .error)
        XCTAssertEqual(decoded.message, "failure")
        XCTAssertEqual(decoded.sessionID, "test-session")
    }

    func testMakeUsesShortFileName() {
        let event = LogEvent.make(
            level: .info,
            message: "hello",
            sessionID: nil,
            userID: nil,
            file: "/tmp/project/Feature.swift",
            function: "test()",
            line: 10
        )

        XCTAssertEqual(event.file, "Feature.swift")
        XCTAssertEqual(event.function, "test()")
        XCTAssertEqual(event.line, 10)
    }
}
