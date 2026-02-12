//
//  FileSystemEvent.swift
//  FileSystem
//
//  Created by Anupam Katiyar on 12/02/26.
//

enum FileSystemEvent {
    case created
    case modified
    case deleted
}

protocol FileSystemObserver: AnyObject {
    func onEvent(entity: FileSystemEntity, event: FileSystemEvent)
}

protocol Observable {
    func addObserver(_ observer: FileSystemObserver)
    func removeObserver(_ observer: FileSystemObserver)
}


class WeakObserver {
    weak var observer: FileSystemObserver?
    
    init(_ observer: FileSystemObserver) {
        self.observer = observer
    }
}
