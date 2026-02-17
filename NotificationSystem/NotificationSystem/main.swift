//
//  main.swift
//  NotificationSystem
//
//  Created by Anupam Katiyar on 17/02/26.
//

import Foundation


let notification = NotificationBuilder()
                    .setUser(111)
                    .setTitle("Title")
                    .setBody("Body")
                    .setChannels(NotificationChannel.allCases)
                    .build()

let dispatcher = NotificationDispatcher()
dispatcher.dispatch(notification)
