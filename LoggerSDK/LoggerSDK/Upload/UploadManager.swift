import Foundation

public actor UploadManager {
    public struct Configuration: Sendable {
        public var batchSize: Int
        public var flushInterval: TimeInterval
        public var retryPolicy: RetryPolicy

        public init(
            batchSize: Int = 50,
            flushInterval: TimeInterval = 30,
            retryPolicy: RetryPolicy = RetryPolicy()
        ) {
            self.batchSize = max(1, batchSize)
            self.flushInterval = max(1, flushInterval)
            self.retryPolicy = retryPolicy
        }
    }

    private let storage: any LogStorage
    private let apiClient: any APIClient
    private let configuration: Configuration
    private var periodicTask: Task<Void, Never>?
    private var isRunning = false

    public init(
        storage: any LogStorage,
        apiClient: any APIClient,
        configuration: Configuration = Configuration()
    ) {
        self.storage = storage
        self.apiClient = apiClient
        self.configuration = configuration
    }

    public func start() {
        guard !isRunning else { return }
        isRunning = true

        periodicTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(configuration.flushInterval))
                guard !Task.isCancelled else { break }
                try? await flushNow()
            }
        }
    }

    public func stop() {
        isRunning = false
        periodicTask?.cancel()
        periodicTask = nil
    }

    public func enqueue(_ event: LogEvent) async throws {
        try await storage.append(event)
        let pendingCount = try await storage.pendingCount()
        if pendingCount >= configuration.batchSize {
            try await flushNow()
        }
    }

    public func flushNow() async throws {
        var attempt = 1

        while true {
            let pending = try await storage.fetchPending(limit: configuration.batchSize)
            guard !pending.isEmpty else { return }

            do {
                let response = try await apiClient.upload(logs: pending)
                try await storage.markUploaded(ids: response.acceptedIDs)
                return
            } catch let error as UploadError {
                if case .payloadTooLarge = error, pending.count > 1 {
                    let midpoint = pending.count / 2
                    let firstHalf = Array(pending.prefix(midpoint))
                    let secondHalf = Array(pending.suffix(from: midpoint))
                    _ = try await apiClient.upload(logs: firstHalf)
                    try await storage.markUploaded(ids: firstHalf.map(\.id))
                    _ = try await apiClient.upload(logs: secondHalf)
                    try await storage.markUploaded(ids: secondHalf.map(\.id))
                    return
                }

                guard configuration.retryPolicy.shouldRetry(error: error, attempt: attempt) else {
                    throw error
                }
            } catch {
                guard configuration.retryPolicy.shouldRetry(error: error, attempt: attempt) else {
                    throw error
                }
            }

            let delay = configuration.retryPolicy.delay(for: attempt)
            attempt += 1
            try await Task.sleep(for: .seconds(delay))
        }
    }
}
