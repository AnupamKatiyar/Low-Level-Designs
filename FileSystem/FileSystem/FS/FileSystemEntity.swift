//
//  FileSystemEntity.swift
//  FileSystem
//
//  Created by Anupam Katiyar on 12/02/26.
//

import Foundation

protocol FileSystemProtocol {
    var name: String { get set }
    var permission: Permission { get set }
    var createdAt: Date { get set }
    var modifiedAt: Date { get set }
}


//Cmposit Pattern
class FileSystemEntity: FileSystemProtocol { //Abstract

    private var observers: [WeakObserver] = []
    
    var name: String
    
    var permission: Permission
    
    var createdAt: Date
    
    var modifiedAt: Date
    
    init(name: String, permission: Permission) {
        self.name = name
        self.permission = permission
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    func setPermission(_ permission: Permission) {
        self.permission = permission
    }
    
    func updateTime() {
        self.modifiedAt = Date()
        notify(.modified)
    }
}


extension FileSystemEntity: Observable {
    
    func addObserver(_ observer: any FileSystemObserver) {
        observers.append(WeakObserver(observer))
    }
    
    func removeObserver(_ observer: any FileSystemObserver) {
        observers.removeAll { $0.observer === observer }
    }
    
    func notify(_ event: FileSystemEvent) {
        observers.forEach({ $0.observer?.onEvent(entity: self, event: event) })
    }
}
