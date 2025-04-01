//
//  SettingsPage.swift
//  WinterArc
//
//  Created by Hriday Chhabria on 12/28/24.
//
import SwiftUI
import UserNotifications
import SwiftData
import Foundation

struct SettingsPage: View {
    @State private var notificationsEnabled: Bool = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    @State private var notificationTime: Date = UserDefaults.standard.object(forKey: "notificationTime") as? Date ?? Date()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Notifications")) {
                    Toggle(isOn: $notificationsEnabled) {
                        Text("Enable Notifications")
                    }
                    .onChange(of: notificationsEnabled) { newValue in
                        handleNotificationToggle(isEnabled: newValue)
                    }

                    if notificationsEnabled {
                        HStack {
                            Text("Daily Notification Time")
                            Spacer()
                            DatePicker("", selection: $notificationTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .onChange(of: notificationTime) { newTime in
                                    saveNotificationTime()
                                    scheduleNotification(at: newTime)
                                }
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                loadSettings()
            }
        }
    }

    private func handleNotificationToggle(isEnabled: Bool) {
        saveNotificationsEnabled(isEnabled)
        if isEnabled {
            requestNotificationPermissions()
        } else {
            cancelNotifications()
        }
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            } else if !granted {
                DispatchQueue.main.async {
                    notificationsEnabled = false
                    saveNotificationsEnabled(false)
                }
            }
        }
    }

    private func scheduleNotification(at time: Date) {
        let center = UNUserNotificationCenter.current()

        center.removeAllPendingNotificationRequests()

        let content = UNMutableNotificationContent()
        content.title = "Habit Reminder"
        content.body = "Don't forget to update your habits today!"
        content.sound = .default

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: "dailyHabitReminder", content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    private func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private func saveNotificationsEnabled(_ isEnabled: Bool) {
        UserDefaults.standard.set(isEnabled, forKey: "notificationsEnabled")
    }

    private func saveNotificationTime() {
        UserDefaults.standard.set(notificationTime, forKey: "notificationTime")
    }

    private func loadSettings() {
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        if let savedTime = UserDefaults.standard.object(forKey: "notificationTime") as? Date {
            notificationTime = savedTime
        }
    }
}
