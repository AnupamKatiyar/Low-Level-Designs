//
//  SMSSender.swift
//  NotificationSystem
//
//  Created by Anupam Katiyar on 17/02/26.
//


class SMSSender: NotificationSender {
    func send(_ notification: Notification) {
        print("Sending SMS to \(notification.userId)")
    }
}
