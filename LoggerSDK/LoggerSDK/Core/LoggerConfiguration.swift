import Foundation

public struct LoggerConfiguration: Sendable {
    public var minimumLevel: LogLevel
    public var destinations: [any LogDestination]
    public var sessionID: String
    public var defaultCategory: String?
    public var batching: BatchingConfiguration
    public var redactionKeys: Set<String>

    public init(
        minimumLevel: LogLevel = .debug,
        destinations: [any LogDestination] = [ConsoleDestination()],
        sessionID: String = UUID().uuidString,
        defaultCategory: String? = nil,
        batching: BatchingConfiguration = .default,
        redactionKeys: Set<String> = ["password", "token", "apiKey", "secret"]
    ) {
        self.minimumLevel = minimumLevel
        self.destinations = destinations
        self.sessionID = sessionID
        self.defaultCategory = defaultCategory
        self.batching = batching
        self.redactionKeys = redactionKeys
    }

    public static func `default`() -> LoggerConfiguration {
        LoggerConfiguration()
    }

    public static func development() -> LoggerConfiguration {
        LoggerConfiguration(
            minimumLevel: .debug,
            destinations: [ConsoleDestination(minimumLevel: .debug, prettyPrint: true)],
            batching: .immediate
        )
    }

    public static func production(
        remoteEndpoint: URL,
        apiKey: String? = nil,
        fileDirectory: URL? = nil
    ) throws -> LoggerConfiguration {
        let fileStorage = try FileStorage(configuration: .init(
            directory: fileDirectory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                .appendingPathComponent("LoggerSDK", isDirectory: true)
        ))
        let sqliteStorage = try SQLiteStorage(configuration: .init(
            databaseURL: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                .appendingPathComponent("LoggerSDK", isDirectory: true)
                .appendingPathComponent("logs.sqlite")
        ))
        let apiClient = URLSessionAPIClient(configuration: .init(
            endpoint: remoteEndpoint,
            apiKey: apiKey
        ))
        let uploadManager = UploadManager(
            storage: sqliteStorage,
            apiClient: apiClient,
            configuration: .init()
        )

        return LoggerConfiguration(
            minimumLevel: .info,
            destinations: [
                ConsoleDestination(minimumLevel: .warn, useOSLog: true, prettyPrint: false),
                FileDestination(storage: fileStorage),
                RemoteDestination(storage: sqliteStorage, uploadManager: uploadManager)
            ],
            batching: .default
        )
    }
}
