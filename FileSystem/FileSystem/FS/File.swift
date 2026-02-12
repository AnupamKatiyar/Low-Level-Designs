//
//  File.swift
//  FileSystem
//
//  Created by Anupam Katiyar on 12/02/26.
//

class File: FileSystemEntity {
    
    private(set) var content: String?
    private(set) var size: Int
    private(set) var fileType: String
    
    init(name: String, fileType: String, permission: Permission, content: String? = nil) {
        
        self.content = content
        self.size = content?.count ?? 0
        self.fileType = fileType

        super.init(name: name, permission: permission)
        
        notify(.created)
    }
    
    func write(content: String) {
        self.content = content
        self.size = content.count
        self.updateTime()
    }
}
