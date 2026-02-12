//
//  Directory.swift
//  FileSystem
//
//  Created by Anupam Katiyar on 12/02/26.
//

class Directory: FileSystemEntity {
    
    var childrens = [String: FileSystemEntity]()
    
    func add(entity: FileSystemEntity) {
        childrens[entity.name] = entity
        self.updateTime()
        
        notify(.created)
    }
    
    func remove(name: String) {
        childrens.removeValue(forKey: name)
        self.updateTime()
        
        notify(.deleted)
    }
    
    func get(child name: String) -> FileSystemEntity? {
        return self.childrens[name]
    }
    
    func list() -> [String] {
        return Array(childrens.keys)
    }
}
