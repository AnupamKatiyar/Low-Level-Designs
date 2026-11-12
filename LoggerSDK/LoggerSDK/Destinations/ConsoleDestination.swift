import Foundation
import os

public struct ConsoleDestination: LogDestination {
    public let identifier: String
    public var minimumLevel: LogLevel
    public var useOSLog: Bool
    public var prettyPrint: Bool
    private let subsystem: String

    public init(
        identifier: String = "console",
        minimumLevel: LogLevel = .debug,
        useOSLog: Bool = true,
        prettyPrint: Bool = true,
        subsystem: String = Bundle.main.bundleIdentifier ?? "LoggerSDK"
    ) {
        self.identifier = identifier
        self.minimumLevel = minimumLevel
        self.useOSLog = useOSLog
        self.prettyPrint = prettyPrint
        self.subsystem = subsystem
    }

    public func write(_ event: LogEvent) async throws {
        let line = LogFormatting.formatConsoleLine(for: event)

        #if DEBUG
        if prettyPrint {
            print(line)
        }
        #endif

        if useOSLog {
            let category = event.category ?? "default"
            let logger = os.Logger(subsystem: subsystem, category: category)
            logger.log(level: event.level.osLogType, "\(line, privacy: .public)")
        }
    }

    public func flush() async throws {}
}
