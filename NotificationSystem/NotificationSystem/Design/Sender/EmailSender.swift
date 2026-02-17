//
//  EmailSender.swift
//  NotificationSystem
//
//  Created by Anupam Katiyar on 17/02/26.
//


class EmailSender: NotificationSender {
    func send(_ notification: Notification) {
        print("Sending Email to \(notification.userId)")
    }
}
