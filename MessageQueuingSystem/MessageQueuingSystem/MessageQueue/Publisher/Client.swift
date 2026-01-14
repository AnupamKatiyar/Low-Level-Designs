//
//  Client.swift
//  MessageQueuingSystem
//
//  Created by Anupam Katiyar on 14/01/26.
//

import Foundation

class Client {
    
    private var service: PublisherService
    private var uniqueKey = 0
    
    init(_ service: PublisherService) {
        self.service = service
    }
    
    func send(message: String) {
        uniqueKey += 1
        service.sendMessage(key: "test \(uniqueKey)", value: message, source: "Client")
    }
    
}
