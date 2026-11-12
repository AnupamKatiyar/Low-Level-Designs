import Foundation

public actor FileStorage: LogStorage {
    public struct Configuration: Sendable {
        public var directory: URL
        public var fileName: String
        public var maxFileSize: Int
        public var maxRotatedFiles: Int

        public init(
            directory: URL,
            fileName: String = "logs.jsonl",
            maxFileSize: Int = 5_242_880,
            maxRotatedFiles: Int = 5
        ) {
            self.directory = directory
            self.fileName = fileName
            self.maxFileSize = maxFileSize
            self.maxRotatedFiles = max(1, maxRotatedFiles)
        }
    }

    private let configuration: Configuration
    private let encoder: JSONEncoder
    private let fileManager: FileManager

    public init(configuration: Configuration, fileManager: FileManager = .default) throws {
        self.configuration = configuration
        self.fileManager = fileManager
        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        try fileManager.createDirectory(
            at: configuration.directory,
            withIntermediateDirectories: true
        )
    }

    private var activeFileURL: URL {
        configuration.directory.appendingPathComponent(configuration.fileName)
    }

    public func append(_ event: LogEvent) async throws {
        let data = try encoder.encode(event)
        var line = data
        line.append(0x0A)

        let fileURL = activeFileURL
        if !fileManager.fileExists(atPath: fileURL.path) {
            fileManager.createFile(atPath: fileURL.path, contents: nil)
        }

        let handle = try FileHandle(forWritingTo: fileURL)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: line)

        try rotateIfNeeded()
    }

    public func fetchPending(limit: Int) async throws -> [LogEvent] {
        []
    }

    public func markUploaded(ids: [UUID]) async throws {}

    public func delete(olderThan date: Date) async throws {
        let files = try logFiles()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        for fileURL in files {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = content.split(separator: "\n", omittingEmptySubsequences: true)
            let keptLines: [String] = try lines.compactMap { line in
                guard let data = String(line).data(using: .utf8),
                      let event = try? decoder.decode(LogEvent.self, from: data) else {
                    return String(line)
                }
                return event.timestamp >= date ? String(line) : nil
            }

            if keptLines.isEmpty {
                try? fileManager.removeItem(at: fileURL)
            } else {
                try keptLines.joined(separator: "\n").appending("\n").write(to: fileURL, atomically: true, encoding: .utf8)
            }
        }
    }

    public func count() async throws -> Int {
        let fileURL = activeFileURL
        guard fileManager.fileExists(atPath: fileURL.path) else { return 0 }
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        return content.split(separator: "\n", omittingEmptySubsequences: true).count
    }

    public func pendingCount() async throws -> Int {
        0
    }

    public func flush() async throws {}

    private func rotateIfNeeded() throws {
        let fileURL = activeFileURL
        guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
              let fileSize = attributes[.size] as? Int,
              fileSize >= configuration.maxFileSize else {
            return
        }

        for index in stride(from: configuration.maxRotatedFiles - 1, through: 1, by: -1) {
            let source = rotatedFileURL(index: index)
            let destination = rotatedFileURL(index: index + 1)
            if fileManager.fileExists(atPath: source.path) {
                if fileManager.fileExists(atPath: destination.path) {
                    try fileManager.removeItem(at: destination)
                }
                try fileManager.moveItem(at: source, to: destination)
            }
        }

        let firstRotated = rotatedFileURL(index: 1)
        if fileManager.fileExists(atPath: firstRotated.path) {
            try fileManager.removeItem(at: firstRotated)
        }
        try fileManager.moveItem(at: fileURL, to: firstRotated)
        fileManager.createFile(atPath: fileURL.path, contents: nil)
    }

    private func rotatedFileURL(index: Int) -> URL {
        let baseName = (configuration.fileName as NSString).deletingPathExtension
        let ext = (configuration.fileName as NSString).pathExtension
        let name = ext.isEmpty ? "\(baseName).\(index)" : "\(baseName).\(index).\(ext)"
        return configuration.directory.appendingPathComponent(name)
    }

    private func logFiles() throws -> [URL] {
        let contents = try fileManager.contentsOfDirectory(
            at: configuration.directory,
            includingPropertiesForKeys: nil
        )
        return contents.filter { $0.lastPathComponent.hasPrefix("logs") }
    }
}
