//
//  ConsumerService.swift
//  MessageQueuingSystem
//
//  Created by Anupam Katiyar on 14/01/26.
//

protocol ConsumerService {
    func consumeMessage() -> Message?
    
    func ack(_ messageId: Message)
    func fail(_ messageId: Message)
}

extension ConsumerService {
    func ack() {
    }
    
    func fail() {
    }
}
