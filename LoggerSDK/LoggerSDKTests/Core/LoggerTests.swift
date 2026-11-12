import XCTest
@testable import LoggerSDK

final class LoggerTests: XCTestCase {
    func testMinimumLevelFiltering() async {
        let destination = MockLogDestination(minimumLevel: .trace)
        let logger = Logger(configuration: LoggerConfiguration(
            minimumLevel: .warn,
            destinations: [destination],
            batching: .immediate
        ))

        logger.debug("hidden")
        logger.warn("visible")

        await logger.flush()

        XCTAssertEqual(destination.events.count, 1)
        XCTAssertEqual(destination.events.first?.level, .warn)
        XCTAssertEqual(destination.events.first?.message, "visible")
    }

    func testMetadataRedaction() async {
        let destination = MockLogDestination()
        let logger = Logger(configuration: LoggerConfiguration(
            minimumLevel: .debug,
            destinations: [destination],
            batching: .immediate,
            redactionKeys: ["token"]
        ))

        logger.info("login", metadata: ["token": "secret", "user": "alice"])
        await logger.flush()

        XCTAssertEqual(destination.events.first?.metadata["token"], "[REDACTED]")
        XCTAssertEqual(destination.events.first?.metadata["user"], "alice")
    }

    func testSetUserID() async {
        let destination = MockLogDestination()
        let logger = Logger(configuration: LoggerConfiguration(
            destinations: [destination],
            batching: .immediate
        ))

        logger.setUserID("user-42")
        logger.info("action")
        await logger.flush()

        XCTAssertEqual(destination.events.first?.userID, "user-42")
    }
}
