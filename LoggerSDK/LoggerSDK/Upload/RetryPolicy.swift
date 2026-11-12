import Foundation

public struct RetryPolicy: Sendable, Equatable {
    public var maxAttempts: Int
    public var baseDelay: TimeInterval
    public var maxDelay: TimeInterval
    public var jitter: Bool
    public var retryableHTTPStatusCodes: Set<Int>

    public init(
        maxAttempts: Int = 5,
        baseDelay: TimeInterval = 2.0,
        maxDelay: TimeInterval = 60.0,
        jitter: Bool = true,
        retryableHTTPStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504]
    ) {
        self.maxAttempts = max(1, maxAttempts)
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.jitter = jitter
        self.retryableHTTPStatusCodes = retryableHTTPStatusCodes
    }

    public func delay(for attempt: Int) -> TimeInterval {
        let exponential = baseDelay * pow(2.0, Double(max(0, attempt - 1)))
        let capped = min(exponential, maxDelay)
        guard jitter else { return capped }

        let jitterRange = capped * 0.2
        return capped + Double.random(in: -jitterRange...jitterRange)
    }

    public func shouldRetry(error: Error, attempt: Int) -> Bool {
        guard attempt < maxAttempts else { return false }

        if let uploadError = error as? UploadError {
            switch uploadError {
            case .unauthorized, .clientError:
                return false
            case .retryable, .network, .invalidResponse:
                return true
            case .payloadTooLarge:
                return attempt < maxAttempts
            }
        }

        return true
    }

    public func shouldRetry(httpStatusCode: Int, attempt: Int) -> Bool {
        guard attempt < maxAttempts else { return false }
        return retryableHTTPStatusCodes.contains(httpStatusCode)
    }
}
