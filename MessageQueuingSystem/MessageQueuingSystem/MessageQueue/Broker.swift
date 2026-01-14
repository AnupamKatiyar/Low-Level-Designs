//
//  Broker.swift
//  MessageQueuingSystem
//
//  Created by Anupam Katiyar on 14/01/26.
//


//In a single-process design, Broker is a Singleton to protect ordering and in-memory state. In a distributed system, Broker becomes a logical singleton implemented via partitioning and leader election.

class Broker: PublisherService, ConsumerService {

    static let instance = Broker()
    
    private var brokerService: BrokerService
    
    private init() {
        let msgRepo = MessageRepository()
        brokerService = BrokerServiceImpl(msgRepo!, queueCapacity: 5) //Capacity can be in broker configuration
    }

    func sendMessage(key: String, value: String, source: String) {
        Task {
            try await brokerService.publish(key: key, value: value, source: source)
        }
    }

    func consumeMessage() -> Message? {
        return brokerService.consume()
    }
    
    func ack(_ message: Message) {
        brokerService.ack(message)
    }
    
    func fail(_ message: Message) {
        brokerService.addToDLQ(message)
    }
}
