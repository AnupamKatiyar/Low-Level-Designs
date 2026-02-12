//
//  FileSystem.swift
//  FileSystem
//
//  Created by Anupam Katiyar on 12/02/26.
//
import Foundation

class FileSystem {
    
    static let getInstance = FileSystem()
    
    private(set) var root: Directory
    
    private init() {
        root = FileSystemFactory.createDirectory("root", Permission.default)
    }
    
    @discardableResult
    func createFile(_ parent: Directory, _ name: String, _ content: String, _ permission: Permission = .default) -> File {
        let file = FileSystemFactory.createFile(name, content, permission, "text")
        parent.add(entity: file)
        return file
    }
    
    func createDirectory(_ parent: Directory, _ name: String, _ permission: Permission = .default) -> Directory {
        let directory = FileSystemFactory.createDirectory(name, permission)
        parent.add(entity: directory)
        return directory
    }
    
    func delete(_ directory: Directory, name: String) {
        directory.remove(name: name)
    }
    
    
}
