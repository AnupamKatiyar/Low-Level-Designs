import Foundation
import SwiftData


protocol BrokerService {
    func publish(key: String, value: String, source: String) async throws
    func consume() -> Message?
    
    func ack(_ message: Message)
    func addToDLQ(_ message: Message) 
}

class BrokerServiceImpl: BrokerService {
    
    private let repo: MessageRepositoryService
    private let capacity: Int
    private var queue: [Message] = [] //Can use DLL for optimized version

    init(_ repo: MessageRepositoryService, queueCapacity: Int) {
        self.repo = repo
        self.capacity = queueCapacity
        try? self.refillQueueIfNeeded(includeDead: true)
    }

    // MARK: - Enqueue
    func publish(key: String, value: String, source: String) async throws {
        let msg = try repo.insert(key: key, value: value, source: source)
        queue.append(msg)
    }

    // MARK: - Dequeue
    func consume() -> Message? {
        // Refill the in-memory queue from DB if needed
        try? refillQueueIfNeeded()

        if queue.isEmpty { return nil }

        return queue.removeFirst()
    }

    // MARK: - Acknowledge
    func ack(_ message: Message) {
        try? repo.markStatus(.done, for: message.key)
    }
    
    func addToDLQ(_ message: Message) {
        try? repo.markStatus(.deadLetter, for: message.key)
    }

    // MARK: - Helpers
    internal func refillQueueIfNeeded(includeDead: Bool = false) throws {
        if queue.count >= capacity { return }
        let needed = capacity - queue.count
        let pending = try repo.fetchPending(limit: needed, includeDead: includeDead)
        for msg in pending {
            queue.append(msg)
        }
    }
}

