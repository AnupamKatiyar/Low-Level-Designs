//
//  NotificationSenderFactory.swift
//  NotificationSystem
//
//  Created by Anupam Katiyar on 17/02/26.
//


class NotificationSenderFactory {

    static func getSender(channel: NotificationChannel) -> NotificationSender {
        switch channel {
        case .Push:
            return PushSender()
        case .Email:
            return EmailSender()
        case .SMS:
            return SMSSender()
        }
    }
}
