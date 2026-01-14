// MessageQueuingSystem.swift

import Foundation

// MARK: - Broker

/// A simple in-memory message broker singleton that manages a queue of messages.
public final class Broker {
    public static let instance = Broker()
    
    private var messages: [String] = []
    private let queue = DispatchQueue(label: "BrokerQueue", attributes: .concurrent)
    
    private init() {}
    
    /// Adds a message to the broker's queue.
    /// - Parameter message: The message to enqueue.
    public func enqueue(_ message: String) {
        queue.async(flags: .barrier) {
            self.messages.append(message)
        }
    }
    
    /// Removes and returns the next message from the queue, if any.
    /// - Returns: The next message or nil if queue is empty.
    public func dequeue() -> String? {
        var message: String?
        queue.sync(flags: .barrier) {
            if !self.messages.isEmpty {
                message = self.messages.removeFirst()
            }
        }
        return message
    }
}

// MARK: - Client

/// A publisher client that sends messages to the broker.
public final class Client {
    private let broker: Broker
    
    /// Creates a new client with a broker instance.
    /// - Parameter broker: The broker to send messages to.
    public init(_ broker: Broker = .instance) {
        self.broker = broker
    }
    
    /// Sends a message to the broker.
    /// - Parameter message: The message to send.
    public func send(message: String) {
        broker.enqueue(message)
    }
}

// MARK: - Consumer

/// A pull-based consumer that processes messages from a broker.
public final class Consumer {
    private let service: Broker
    
    /// Creates a new consumer with a broker instance.
    /// - Parameter service: The broker to consume messages from.
    public init(service: Broker = .instance) {
        self.service = service
    }
    
    /// Pulls one message from the broker and processes it if available.
    public func doWork() {
        if let message = service.dequeue() {
            process(message: message)
        }
    }
    
    private func process(message: String) {
        // For demo purposes, just print the message.
        print("Processed message: \(message)")
    }
}
