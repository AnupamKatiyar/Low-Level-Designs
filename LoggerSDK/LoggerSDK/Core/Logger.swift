import Foundation

public final class Logger: LoggerProtocol, @unchecked Sendable {
    public static let shared = Logger(configuration: .default())

    private let logActor: LogActor
    private let lock = NSLock()
    private var _configuration: LoggerConfiguration
    private var _userID: String?
    private var operationChain: Task<Void, Never>?

    public init(configuration: LoggerConfiguration) {
        self._configuration = configuration
        self.logActor = LogActor(configuration: configuration)
        startUploadManagersIfNeeded(configuration)
    }

    public var configuration: LoggerConfiguration {
        lock.lock()
        defer { lock.unlock() }
        return _configuration
    }

    public func configure(_ configuration: LoggerConfiguration) {
        lock.lock()
        _configuration = configuration
        lock.unlock()

        Task {
            await logActor.updateConfiguration(configuration)
            startUploadManagersIfNeeded(configuration)
        }
    }

    public func setUserID(_ id: String?) {
        lock.lock()
        _userID = id
        lock.unlock()
    }

    public func log(
        _ level: LogLevel,
        _ message: String,
        category: String? = nil,
        metadata: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let config = configuration
        guard level >= config.minimumLevel else { return }

        let userID: String?
        lock.lock()
        userID = _userID
        lock.unlock()

        let resolvedCategory = category ?? config.defaultCategory
        let redactedMetadata = Redactor.redact(metadata: metadata, keys: config.redactionKeys)

        let event = LogEvent.make(
            level: level,
            message: message,
            category: resolvedCategory,
            metadata: redactedMetadata,
            sessionID: config.sessionID,
            userID: userID,
            file: file,
            function: function,
            line: line
        )

        schedule {
            await self.logActor.enqueue(event)
        }
    }

    public func flush() async {
        await waitForPendingOperations()
        await logActor.flush()
    }

    public func shutdown() async {
        await waitForPendingOperations()
        await logActor.shutdown()
        stopUploadManagersIfNeeded(configuration)
    }

    private func schedule(_ operation: @escaping @Sendable () async -> Void) {
        lock.lock()
        let previous = operationChain
        operationChain = Task {
            await previous?.value
            await operation()
        }
        lock.unlock()
    }

    private func waitForPendingOperations() async {
        var pending: Task<Void, Never>?
        NSLock().withLock {
            pending = operationChain
        }
        await pending?.value
    }

    private func startUploadManagersIfNeeded(_ configuration: LoggerConfiguration) {
        for destination in configuration.destinations {
            guard let remote = destination as? RemoteDestination else { continue }
            Task { await remote.startUploads() }
        }
    }

    private func stopUploadManagersIfNeeded(_ configuration: LoggerConfiguration) {
        for destination in configuration.destinations {
            guard let remote = destination as? RemoteDestination else { continue }
            Task { await remote.stopUploads() }
        }
    }
}










