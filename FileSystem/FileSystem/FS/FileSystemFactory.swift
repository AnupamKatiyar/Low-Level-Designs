//
//  FileSystemFactory.swift
//  FileSystem
//
//  Created by Anupam Katiyar on 12/02/26.
//

class FileSystemFactory {
    
    static func createFile(_ name: String, _ content: String, _ permission: Permission, _ fileType: String) -> File {
        return File(name: name, fileType: fileType, permission: permission, content: content)
    }
    
    static func createDirectory(_ name: String, _ permission: Permission) -> Directory {
        return Directory(name: name, permission: permission)
    }
}
