import Foundation

public struct RemoteDestination: LogDestination {
    public let identifier: String
    public var minimumLevel: LogLevel
    private let storage: SQLiteStorage
    private let uploadManager: UploadManager

    public init(
        storage: SQLiteStorage,
        uploadManager: UploadManager,
        identifier: String = "remote",
        minimumLevel: LogLevel = .info
    ) {
        self.storage = storage
        self.uploadManager = uploadManager
        self.identifier = identifier
        self.minimumLevel = minimumLevel
    }

    public func write(_ event: LogEvent) async throws {
        try await uploadManager.enqueue(event)
    }

    public func writeBatch(_ events: [LogEvent]) async throws {
        for event in events {
            try await uploadManager.enqueue(event)
        }
    }

    public func flush() async throws {
        try await uploadManager.flushNow()
        try await storage.flush()
    }

    public func startUploads() async {
        await uploadManager.start()
    }

    public func stopUploads() async {
        await uploadManager.stop()
    }
}
