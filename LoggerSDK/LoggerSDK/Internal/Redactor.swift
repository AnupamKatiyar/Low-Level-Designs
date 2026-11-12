import Foundation

enum Redactor {
    static func redact(metadata: [String: String], keys: Set<String>) -> [String: String] {
        guard !keys.isEmpty else { return metadata }

        var redacted = metadata
        for key in metadata.keys where keys.contains(where: { $0.caseInsensitiveCompare(key) == .orderedSame }) {
            redacted[key] = "[REDACTED]"
        }
        return redacted
    }
}

