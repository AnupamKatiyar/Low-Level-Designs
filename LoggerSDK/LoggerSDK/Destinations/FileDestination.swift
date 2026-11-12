import Foundation

public struct FileDestination: LogDestination {
    public let identifier: String
    public var minimumLevel: LogLevel
    private let storage: FileStorage

    public init(
        storage: FileStorage,
        identifier: String = "file",
        minimumLevel: LogLevel = .debug
    ) {
        self.storage = storage
        self.identifier = identifier
        self.minimumLevel = minimumLevel
    }

    public func write(_ event: LogEvent) async throws {
        try await storage.append(event)
    }

    public func writeBatch(_ events: [LogEvent]) async throws {
        for event in events {
            try await storage.append(event)
        }
    }

    public func flush() async throws {
        try await storage.flush()
    }
}
