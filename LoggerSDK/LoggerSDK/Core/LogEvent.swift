import Foundation

public struct LogEvent: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let timestamp: Date
    public let level: LogLevel
    public let message: String
    public let category: String?
    public let metadata: [String: String]
    public let file: String
    public let function: String
    public let line: Int
    public let threadID: String
    public let sessionID: String?
    public let userID: String?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        level: LogLevel,
        message: String,
        category: String? = nil,
        metadata: [String: String] = [:],
        file: String,
        function: String,
        line: Int,
        threadID: String,
        sessionID: String? = nil,
        userID: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.message = message
        self.category = category
        self.metadata = metadata
        self.file = file
        self.function = function
        self.line = line
        self.threadID = threadID
        self.sessionID = sessionID
        self.userID = userID
    }
}

extension LogEvent {
    static func make(
        level: LogLevel,
        message: String,
        category: String? = nil,
        metadata: [String: String] = [:],
        sessionID: String?,
        userID: String?,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) -> LogEvent {
        LogEvent(
            level: level,
            message: message,
            category: category,
            metadata: metadata,
            file: (file as NSString).lastPathComponent,
            function: function,
            line: line,
            threadID: LogEvent.currentThreadID(),
            sessionID: sessionID,
            userID: userID
        )
    }

    private static func currentThreadID() -> String {
        if Thread.isMainThread {
            return "main"
        }
        return String(format: "%p", Thread.current)
    }
}
