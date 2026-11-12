import XCTest
@testable import LoggerSDK

final class LogLevelTests: XCTestCase {
    func testComparableOrdering() {
        XCTAssertTrue(LogLevel.trace < LogLevel.debug)
        XCTAssertTrue(LogLevel.error < LogLevel.fatal)
        XCTAssertEqual(LogLevel.info, LogLevel.info)
    }

    func testLabels() {
        XCTAssertEqual(LogLevel.warn.label, "WARN")
        XCTAssertEqual(LogLevel.fatal.label, "FATAL")
    }
}
