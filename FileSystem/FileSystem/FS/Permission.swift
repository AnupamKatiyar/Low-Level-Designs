//
//  Permission.swift
//  FileSystem
//
//  Created by Anupam Katiyar on 12/02/26.
//

class Permission {
    
    private(set) var read: Bool
    private(set) var write: Bool
    private(set) var execute: Bool
    
    init(read: Bool, write: Bool, execute: Bool) {
        self.read = read
        self.write = write
        self.execute = execute
    }
    
    static var `default`: Permission {
        Permission(read: true, write: true, execute: true)
    }
}
