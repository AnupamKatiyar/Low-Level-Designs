import Foundation
import SwiftData


protocol MessageRepositoryService {
    func insert(key: String, value: String, source: String) throws -> Message
    func fetchByKey(_ key: String) -> Message?
    func fetchPending(limit: Int, includeDead: Bool) throws -> [Message]
    func markStatus(_ status: Message.Status, for task: String) throws
    func delete(_ message: Message) throws
}


/// Repository responsible for CRUD operations for Message using SwiftData
class MessageRepository: MessageRepositoryService {
    
    private let modelContext: ModelContext

    init?() {
        if let container = try? ModelContainer(for: Message.self) {
            self.modelContext = ModelContext(container)
            return
        }
        return nil
    }

    // MARK: - Create
    @discardableResult
    func insert(key: String, value: String, source: String) throws -> Message {
        var msg = self.fetchByKey(key)
        if let msg {
            msg.value = value
        } else {
            msg = Message(key: key, value: value, source: source)
            modelContext.insert(msg!)
        }
        if modelContext.hasChanges {
            try modelContext.save()
        }
        return msg!
    }

    // MARK: - Read
    func fetchPending(limit: Int, includeDead: Bool) throws -> [Message] {
        
        var descriptor = FetchDescriptor<Message>(predicate: getPredicate(includeDead), sortBy: [SortDescriptor(\Message.timestamp, order: .forward)])
        descriptor.fetchLimit = limit

        let results = try modelContext.fetch(descriptor)
        print(results.count)
        return results
    }
    
    private func getPredicate(_ includeDead: Bool) -> Predicate<Message> {
        let done = Message.Status.done.rawValue
        let pending = Message.Status.pending.rawValue

        if includeDead {
            return #Predicate<Message> { $0.statusValue != done }
        } else {
            return #Predicate<Message> { $0.statusValue == pending }
        }
    }
    
//    func fetchInProgress(now: Date = Date()) throws -> [Message] {
//        let descriptor = FetchDescriptor<Message>(
//            predicate: #Predicate { msg in
//                msg.status == Message.Status.inProgress && msg.completed == false && msg.visibilityDeadline != nil && msg.visibilityDeadline! > now
//            },
//            sortBy: [SortDescriptor(\Message.visibilityDeadline, order: .forward)]
//        )
//        return try modelContext.fetch(descriptor)
//    }

    func fetchByKey(_ key: String) -> Message? {
        var descriptor = FetchDescriptor<Message>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    func markStatus(_ status: Message.Status, for task: String) throws {
        if let msg = self.fetchByKey(task) {
            msg.status = status
            try modelContext.save()
        }
    }

    func delete(_ message: Message) throws {
        modelContext.delete(message)
        try modelContext.save()
    }
}
