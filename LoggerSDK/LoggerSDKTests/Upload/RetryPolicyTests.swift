import XCTest
@testable import LoggerSDK

final class RetryPolicyTests: XCTestCase {
    func testExponentialBackoffIsCapped() {
        let policy = RetryPolicy(baseDelay: 2, maxDelay: 10, jitter: false)
        XCTAssertEqual(policy.delay(for: 1), 2)
        XCTAssertEqual(policy.delay(for: 2), 4)
        XCTAssertEqual(policy.delay(for: 10), 10)
    }

    func testDoesNotRetryUnauthorized() {
        let policy = RetryPolicy(maxAttempts: 5)
        XCTAssertFalse(policy.shouldRetry(error: UploadError.unauthorized, attempt: 1))
    }

    func testRetriesNetworkErrors() {
        let policy = RetryPolicy(maxAttempts: 5)
        XCTAssertTrue(policy.shouldRetry(error: UploadError.network("offline"), attempt: 1))
        XCTAssertFalse(policy.shouldRetry(error: UploadError.network("offline"), attempt: 5))
    }
}
