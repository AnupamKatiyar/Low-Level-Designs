import Foundation

public struct BatchingConfiguration: Sendable, Equatable {
    public var enabled: Bool
    public var maxBatchSize: Int
    public var maxWaitInterval: TimeInterval

    public init(
        enabled: Bool = true,
        maxBatchSize: Int = 20,
        maxWaitInterval: TimeInterval = 1.0
    ) {
        self.enabled = enabled
        self.maxBatchSize = max(1, maxBatchSize)
        self.maxWaitInterval = max(0.1, maxWaitInterval)
    }

    public static let immediate = BatchingConfiguration(enabled: false)
    public static let `default` = BatchingConfiguration()
}

actor EventBatcher {
    private let configuration: BatchingConfiguration
    private var buffer: [LogEvent] = []

    init(configuration: BatchingConfiguration) {
        self.configuration = configuration
    }

    func add(_ event: LogEvent) async -> [LogEvent]? {
        guard configuration.enabled else {
            return [event]
        }

        buffer.append(event)

        if buffer.count >= configuration.maxBatchSize {
            return drainBuffer()
        }

        return nil
    }

    func flush() async -> [LogEvent] {
        drainBuffer()
    }

    private func drainBuffer() -> [LogEvent] {
        let batch = buffer
        buffer = []
        return batch
    }
}
