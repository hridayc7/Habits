//
//  ContentView.swift
//  WinterArc
//
//  Created by Hriday Chhabria on 12/28/24.
//


import SwiftUI
import SwiftData
import UserNotifications


struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "checkmark.circle")
            }
//            EntriesPage()
//                .tabItem{
//                    Label("Entries", systemImage: "apple.intelligence")
//                }
            StatsPage()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
            HabitsPage()
                .tabItem {
                    Label("Habits", systemImage: "plus")
                }
            SettingsPage()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}





// MARK: - Previews

#Preview {
    ContentView()
}
