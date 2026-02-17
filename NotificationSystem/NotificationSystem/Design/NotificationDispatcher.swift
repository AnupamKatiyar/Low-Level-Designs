//
//  NotificationDispatcher.swift
//  NotificationSystem
//
//  Created by Anupam Katiyar on 17/02/26.
//


class NotificationDispatcher {

    let preferenceService = UserPreferenceService()

    func dispatch(_ notification: Notification) {

        let enabledChannels = preferenceService.getEnabledChannels(userId: 123)

        for channel in notification.channels where enabledChannels.contains(channel) {

            let sender = NotificationSenderFactory.getSender(channel: channel)
            //Can have retry as well
            
            sender.send(notification)
        }
    }
}
