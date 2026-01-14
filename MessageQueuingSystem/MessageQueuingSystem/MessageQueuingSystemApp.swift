//
//  MessageQueuingSystemApp.swift
//  MessageQueuingSystem
//
//  Created by Anupam Katiyar on 14/01/26.
//

import SwiftUI
import SwiftData

@main
struct MessageQueuingSystemApp: App {
    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Message.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(MessageQueuingSystemApp.sharedModelContainer)
    }
}
