//
//  Notification.swift
//  NotificationSystem
//
//  Created by Anupam Katiyar on 17/02/26.
//

struct Notification {
    let id: String
    let userId: Int
    let title: String
    let body: String
    let channels: [NotificationChannel]
    let metadata: [String: String]
}


enum NotificationChannel: CaseIterable {
    case Email, Push, SMS
}
