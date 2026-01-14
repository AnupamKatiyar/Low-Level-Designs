//
//  Message.swift
//  MessageQueuingSystem
//
//  Created by Anupam Katiyar on 14/01/26.
//

import Foundation
import SwiftData

@Model
final class Message {
    
    /// Unique identifier for the message within a topic/queue
    var key: String
    /// Raw payload for the message
    var value: String
    /// Creation timestamp
    var timestamp: Date
    /// Publisher/source identifier
    var source: String
    
    // 1. Store the status as a String for database filtering
    var statusValue: String

    // 2. Use a computed property for your app logic
    var status: Status {
        get { Status(rawValue: statusValue) ?? .pending }
        set { statusValue = newValue.rawValue }
    }

    init(key: String, value: String, source: String) {
        self.key = key
        self.value = value
        self.timestamp = Date()
        self.source = source
        self.statusValue = Status.pending.rawValue
    }
}

extension Message {
    enum Status: String, Codable, CaseIterable {
        case pending
        case done
        case deadLetter
    }
}
