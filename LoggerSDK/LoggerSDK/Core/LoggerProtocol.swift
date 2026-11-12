import Foundation

public protocol LoggerProtocol: Sendable {
    func log(
        _ level: LogLevel,
        _ message: String,
        category: String?,
        metadata: [String: String],
        file: String,
        function: String,
        line: Int
    )

    func trace(_ message: String, category: String?, metadata: [String: String])
    func debug(_ message: String, category: String?, metadata: [String: String])
    func info(_ message: String, category: String?, metadata: [String: String])
    func warn(_ message: String, category: String?, metadata: [String: String])
    func error(_ message: String, category: String?, metadata: [String: String])
    func fatal(_ message: String, category: String?, metadata: [String: String])

    func setUserID(_ id: String?)
    func flush() async
    func shutdown() async
}

extension LoggerProtocol {
    public func trace(
        _ message: String,
        category: String? = nil,
        metadata: [String: String] = [:]
    ) {
        log(.trace, message, category: category, metadata: metadata, file: #file, function: #function, line: #line)
    }

    public func debug(
        _ message: String,
        category: String? = nil,
        metadata: [String: String] = [:]
    ) {
        log(.debug, message, category: category, metadata: metadata, file: #file, function: #function, line: #line)
    }

    public func info(
        _ message: String,
        category: String? = nil,
        metadata: [String: String] = [:]
    ) {
        log(.info, message, category: category, metadata: metadata, file: #file, function: #function, line: #line)
    }

    public func warn(
        _ message: String,
        category: String? = nil,
        metadata: [String: String] = [:]
    ) {
        log(.warn, message, category: category, metadata: metadata, file: #file, function: #function, line: #line)
    }

    public func error(
        _ message: String,
        category: String? = nil,
        metadata: [String: String] = [:]
    ) {
        log(.error, message, category: category, metadata: metadata, file: #file, function: #function, line: #line)
    }

    public func fatal(
        _ message: String,
        category: String? = nil,
        metadata: [String: String] = [:]
    ) {
        log(.fatal, message, category: category, metadata: metadata, file: #file, function: #function, line: #line)
    }
}
