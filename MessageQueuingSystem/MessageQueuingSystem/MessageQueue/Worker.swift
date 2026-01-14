//
//  Worker.swift
//  MessageQueuingSystem
//
//  Created by Anupam Katiyar on 14/01/26.
//

protocol WorkerService {
    func performJob(_ msg: String)
}

class WorkerImpl: WorkerService {
    func performJob(_ msg: String) {
        print("Worker is performing job with message: \(msg)")
    }
}
