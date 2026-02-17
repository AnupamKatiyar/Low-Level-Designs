//
//  NotificationBuilder.swift
//  NotificationSystem
//
//  Created by Anupam Katiyar on 17/02/26.
//
import Foundation

class NotificationBuilder {

    private var id = UUID().uuidString
    private var userId = -1
    private var title = ""
    private var body = ""
    private var channels: [NotificationChannel] = []

    func setUser(_ userId: Int) -> Self {
        self.userId = userId
        return self
    }

    func setTitle(_ title: String) -> Self {
        self.title = title
        return self
    }

    func setBody(_ body: String) -> Self {
        self.body = body
        return self
    }

    func setChannels(_ channels: [NotificationChannel]) -> Self {
        self.channels = channels
        return self
    }

    func build() -> Notification {
        return Notification(
            id: id,
            userId: userId,
            title: title,
            body: body,
            channels: channels,
            metadata: [:]
        )
    }
}
