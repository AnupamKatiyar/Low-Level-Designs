import Foundation

public struct UploadResponse: Codable, Sendable, Equatable {
    public let acceptedIDs: [UUID]
    public let rejectedIDs: [UUID]

    public init(acceptedIDs: [UUID], rejectedIDs: [UUID] = []) {
        self.acceptedIDs = acceptedIDs
        self.rejectedIDs = rejectedIDs
    }
}

public enum UploadError: Error, Sendable, Equatable {
    case network(String)
    case unauthorized
    case clientError(Int)
    case retryable(Int)
    case payloadTooLarge
    case invalidResponse
}

public protocol APIClient: Sendable {
    func upload(logs: [LogEvent]) async throws -> UploadResponse
}

public struct UploadPayload: Codable, Sendable {
    public let batchID: UUID
    public let sessionID: String?
    public let events: [LogEvent]

    enum CodingKeys: String, CodingKey {
        case batchID = "batch_id"
        case sessionID = "session_id"
        case events
    }
}

public final class URLSessionAPIClient: APIClient, @unchecked Sendable {
    public struct Configuration: Sendable {
        public var endpoint: URL
        public var apiKey: String?
        public var timeout: TimeInterval
        public var headers: [String: String]

        public init(
            endpoint: URL,
            apiKey: String? = nil,
            timeout: TimeInterval = 30,
            headers: [String: String] = [:]
        ) {
            self.endpoint = endpoint
            self.apiKey = apiKey
            self.timeout = timeout
            self.headers = headers
        }
    }

    private let configuration: Configuration
    private let session: URLSession
    private let encoder: JSONEncoder

    public init(configuration: Configuration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    public func upload(logs: [LogEvent]) async throws -> UploadResponse {
        guard !logs.isEmpty else {
            return UploadResponse(acceptedIDs: [])
        }

        let payload = UploadPayload(
            batchID: UUID(),
            sessionID: logs.first?.sessionID,
            events: logs
        )

        var request = URLRequest(
            url: configuration.endpoint,
            timeoutInterval: configuration.timeout
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let apiKey = configuration.apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        for (key, value) in configuration.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        request.httpBody = try encoder.encode(payload)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw UploadError.network(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UploadError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try decodeResponse(data: data, fallbackIDs: logs.map(\.id))
        case 401, 403:
            throw UploadError.unauthorized
        case 413:
            throw UploadError.payloadTooLarge
        case 400...499:
            throw UploadError.clientError(httpResponse.statusCode)
        default:
            throw UploadError.retryable(httpResponse.statusCode)
        }
    }

    private func decodeResponse(data: Data, fallbackIDs: [UUID]) throws -> UploadResponse {
        if data.isEmpty {
            return UploadResponse(acceptedIDs: fallbackIDs)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let response = try? decoder.decode(UploadResponse.self, from: data) {
            return response
        }

        return UploadResponse(acceptedIDs: fallbackIDs)
    }
}
