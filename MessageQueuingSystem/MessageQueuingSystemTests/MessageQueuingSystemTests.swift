//
//  MessageQueuingSystemTests.swift
//  MessageQueuingSystemTests
//
//  Created by Anupam Katiyar on 14/01/26.
//

import Testing

struct MessageQueuingSystemTests {

    @Test func testBrokerConsumer() async throws {
        
        //Publisher
        let client = Client(Broker.instance)
        for _ in 0..<10 {
            client.send(message: "Hello World!")
        }
        
        #expect(true)
    }
    
    @Test func testConsumer() {
        Task {
            let consumer = Consumer(service: Broker.instance)
            for _ in 0..<10 {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                consumer.doWork()
            }
        }
    }

}
