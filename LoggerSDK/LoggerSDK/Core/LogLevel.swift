import Foundation
import os

public enum LogLevel: Int, Codable, Sendable, Comparable, CaseIterable {
    case trace = 0
    case debug = 1
    case info = 2
    case warn = 3
    case error = 4
    case fatal = 5

    public var label: String {
        switch self {
        case .trace: "TRACE"
        case .debug: "DEBUG"
        case .info: "INFO"
        case .warn: "WARN"
        case .error: "ERROR"
        case .fatal: "FATAL"
        }
    }

    public var osLogType: OSLogType {
        switch self {
        case .trace, .debug: .debug
        case .info: .info
        case .warn: .default
        case .error: .error
        case .fatal: .fault
        }
    }

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
