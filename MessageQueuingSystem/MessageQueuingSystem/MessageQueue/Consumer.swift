//
//  Consumer.swift
//  MessageQueuingSystem
//
//  Created by Anupam Katiyar on 14/01/26.
//


class Consumer {
    
    private let service: ConsumerService
    private let worker : WorkerService
    
    init(service: ConsumerService) {
        self.service = service
        self.worker = WorkerImpl()
    }
    
    func doWork() {
        if let message = service.consumeMessage() {
            worker.performJob(message.value)
            service.ack(message)
        }
    }
}
