//
//  main.swift
//  FileSystem
//
//  Created by Anupam Katiyar on 12/02/26.
//

import Foundation


let logger = LoggingWatcher();


let fs = FileSystem.getInstance

let d1 = fs.createDirectory(fs.root, "Dir 1")
let d2 = fs.createDirectory(fs.root, "Dir 2")

d1.addObserver(logger)

fs.createFile(d1, "f1", "Hi there f1")
fs.createFile(d2, "f2", "Hi there f2")
let fr1 = fs.createFile(fs.root, "fr1", "Hi there fe1")
fs.createFile(fs.root, "f21", "Hi there fr2")

fs.root.addObserver(logger)
fr1.addObserver(logger)

print(fs.root.list())
print(d1.list())
print(d2.list())

