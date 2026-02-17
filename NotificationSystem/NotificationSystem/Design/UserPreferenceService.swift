//
//  UserPreferenceService.swift
//  NotificationSystem
//
//  Created by Anupam Katiyar on 17/02/26.
//


class UserPreferenceService {

    private var preferences: [Int: Set<NotificationChannel>] = [:]

    func getEnabledChannels(userId: Int) -> Set<NotificationChannel> {
        return preferences[userId] ?? [.Push, .SMS, .Email]
    }
}
