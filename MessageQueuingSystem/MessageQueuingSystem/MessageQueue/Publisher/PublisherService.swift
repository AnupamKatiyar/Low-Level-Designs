//
//  BrokerService-MessageQueue.swift
//  MessageQueuingSystem
//
//  Created by Anupam Katiyar on 14/01/26.
//

import Foundation
import SwiftData


protocol PublisherService {
    func sendMessage(key: String, value: String, source: String)
}
