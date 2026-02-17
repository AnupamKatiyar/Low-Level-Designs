//
//  PushSender.swift
//  NotificationSystem
//
//  Created by Anupam Katiyar on 17/02/26.
//

class PushSender: NotificationSender {
    func send(_ notification: Notification) {
        print("Sending PUSH to \(notification.userId)")
    }
}
