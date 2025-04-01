//
//  WinterArc.swift
//  WinterArc
//
//  Created by Hriday Chhabria on 12/28/24.
//


import SwiftUI
import SwiftData

@main
struct WinterArc: App {
    // Create the ModelContainer in a @State property
    @State private var container: ModelContainer = {
        do {
            return try ModelContainer(for: Habit.self, DailyEntry.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            // Pass the container to the root view and its environment
            ContentView()
                .modelContainer(container)
                .onChange(of: container) { newContainer in
                    // This can handle any changes to the container, if necessary
                }
        }
    }
}

