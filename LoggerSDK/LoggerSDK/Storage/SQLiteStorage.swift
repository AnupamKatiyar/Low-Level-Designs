import Foundation
import SQLite3

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

public actor SQLiteStorage: LogStorage {
    public struct Configuration: Sendable {
        public var databaseURL: URL
        public var retentionDays: Int

        public init(databaseURL: URL, retentionDays: Int = 7) {
            self.databaseURL = databaseURL
            self.retentionDays = max(1, retentionDays)
        }
    }

    private let configuration: Configuration
    private var database: OpaquePointer?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(configuration: Configuration) throws {
        self.configuration = configuration
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        let directory = configuration.databaseURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        var db: OpaquePointer?
        let result = sqlite3_open(configuration.databaseURL.path, &db)
        guard result == SQLITE_OK, let db else {
            throw LogStorageError.databaseError("Failed to open database (\(result))")
        }
        database = db
        try Self.execute(database: db,
            sql: """
            CREATE TABLE IF NOT EXISTS log_events (
                id TEXT PRIMARY KEY,
                timestamp REAL NOT NULL,
                level INTEGER NOT NULL,
                payload BLOB NOT NULL,
                uploaded INTEGER DEFAULT 0,
                created_at REAL NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_pending ON log_events(uploaded, timestamp);
            """)
    }

    deinit {
        if let database {
            sqlite3_close(database)
        }
    }

    public func append(_ event: LogEvent) async throws {
        guard let payload = try? encoder.encode(event) else {
            throw LogStorageError.encodingFailed
        }

        let sql = """
            INSERT OR REPLACE INTO log_events (id, timestamp, level, payload, uploaded, created_at)
            VALUES (?, ?, ?, ?, COALESCE((SELECT uploaded FROM log_events WHERE id = ?), 0), ?);
            """
        try withStatement(sql: sql) { statement in
            sqlite3_bind_text(statement, 1, event.id.uuidString, -1, sqliteTransient)
            sqlite3_bind_double(statement, 2, event.timestamp.timeIntervalSince1970)
            sqlite3_bind_int(statement, 3, Int32(event.level.rawValue))
            _ = payload.withUnsafeBytes { bytes in
                sqlite3_bind_blob(statement, 4, bytes.baseAddress, Int32(bytes.count), sqliteTransient)
            }
            sqlite3_bind_text(statement, 5, event.id.uuidString, -1, sqliteTransient)
            sqlite3_bind_double(statement, 6, Date().timeIntervalSince1970)
            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw LogStorageError.databaseError(errorMessage)
            }
        }
    }

    public func fetchPending(limit: Int) async throws -> [LogEvent] {
        let sql = """
            SELECT payload FROM log_events
            WHERE uploaded = 0
            ORDER BY timestamp ASC
            LIMIT ?;
            """
        var events: [LogEvent] = []
        try withStatement(sql: sql) { statement in
            sqlite3_bind_int(statement, 1, Int32(max(1, limit)))
            while sqlite3_step(statement) == SQLITE_ROW {
                guard let blob = sqlite3_column_blob(statement, 0) else { continue }
                let length = Int(sqlite3_column_bytes(statement, 0))
                let data = Data(bytes: blob, count: length)
                guard let event = try? decoder.decode(LogEvent.self, from: data) else {
                    throw LogStorageError.decodingFailed
                }
                events.append(event)
            }
        }
        return events
    }

    public func markUploaded(ids: [UUID]) async throws {
        guard !ids.isEmpty else { return }

        let placeholders = Array(repeating: "?", count: ids.count).joined(separator: ", ")
        let sql = "UPDATE log_events SET uploaded = 1 WHERE id IN (\(placeholders));"

        try withStatement(sql: sql) { statement in
            for (index, id) in ids.enumerated() {
                sqlite3_bind_text(statement, Int32(index + 1), id.uuidString, -1, sqliteTransient)
            }
            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw LogStorageError.databaseError(errorMessage)
            }
        }
    }

    public func delete(olderThan date: Date) async throws {
        let sql = "DELETE FROM log_events WHERE timestamp < ?;"
        try withStatement(sql: sql) { statement in
            sqlite3_bind_double(statement, 1, date.timeIntervalSince1970)
            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw LogStorageError.databaseError(errorMessage)
            }
        }
    }

    public func count() async throws -> Int {
        let sql = "SELECT COUNT(*) FROM log_events;"
        var total = 0
        try withStatement(sql: sql) { statement in
            guard sqlite3_step(statement) == SQLITE_ROW else {
                throw LogStorageError.databaseError(errorMessage)
            }
            total = Int(sqlite3_column_int(statement, 0))
        }
        return total
    }

    public func pendingCount() async throws -> Int {
        let sql = "SELECT COUNT(*) FROM log_events WHERE uploaded = 0;"
        var total = 0
        try withStatement(sql: sql) { statement in
            guard sqlite3_step(statement) == SQLITE_ROW else {
                throw LogStorageError.databaseError(errorMessage)
            }
            total = Int(sqlite3_column_int(statement, 0))
        }
        return total
    }

    public func flush() async throws {
        let cutoff = Date().addingTimeInterval(-Double(configuration.retentionDays) * 86_400)
        try await delete(olderThan: cutoff)
    }

    private var errorMessage: String {
        guard let database else { return "Database unavailable" }
        return String(cString: sqlite3_errmsg(database))
    }

    private static func execute(database: OpaquePointer, sql: String) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(database, sql, nil, nil, &errorMessage)
        guard result == SQLITE_OK else {
            let message = errorMessage.map { String(cString: $0) } ?? "Unknown SQLite error"
            sqlite3_free(errorMessage)
            throw LogStorageError.databaseError(message)
        }
    }

    private func withStatement<T>(sql: String, _ body: (OpaquePointer) throws -> T) throws -> T {
        guard let database else {
            throw LogStorageError.databaseError("Database unavailable")
        }
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK,
              let statement else {
            throw LogStorageError.databaseError(errorMessage)
        }
        defer { sqlite3_finalize(statement) }
        return try body(statement)
    }
}

