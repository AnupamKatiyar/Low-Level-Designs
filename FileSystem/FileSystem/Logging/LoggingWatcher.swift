//
//  LoggingWatcher.swift
//  FileSystem
//
//  Created by Anupam Katiyar on 12/02/26.
//


class LoggingWatcher: FileSystemObserver {
    func onEvent(entity: FileSystemEntity, event: FileSystemEvent) {
        print("[LOG] \(event) on \(entity.name)")
    }
}
