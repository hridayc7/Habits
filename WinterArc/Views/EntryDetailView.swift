//
//  EntryDetailView.swift
//  WinterArc
//
//  Created by Hriday Chhabria on 12/28/24.
//

import SwiftUI
import Foundation
import SwiftData

struct EntryDetailView: View {
    var entry: DailyEntry
    @Query private var habits: [Habit]
    @Environment(\.modelContext) private var modelContext
    
    
    var body: some View {
        VStack {            
            List {
                ForEach(habitsForEntry()) { habit in
                    HStack {
                        Text(habit.name)
                        Spacer()
                        Button(action: {
                            toggleHabitStatus(habit)
                        }) {
                            Image(systemName: entry.habitStatuses[habit.id] == true ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(entry.habitStatuses[habit.id] == true ? .green : .gray)
                        }
                    }
                }
            }
        }
        .onAppear {
            ensureAllHabitsIncluded()
        }
        .navigationTitle(Text(entry.date, style: .date))
    }
    
    private func habitsForEntry() -> [Habit] {
        habits.filter { Calendar.current.isDate($0.creationDate, inSameDayAs: entry.date) || $0.creationDate <= entry.date }
    }
    
    private func toggleHabitStatus(_ habit: Habit) {
        print("Toggling Habit \(habit.name) status for entry on Date: \(entry.date)")

        if entry.habitStatuses[habit.id] == nil {
            print("Initializing habit status to false")
            entry.habitStatuses[habit.id] = false
        }

        entry.habitStatuses[habit.id]?.toggle()

        print("Habit Status after toggle: \(entry.habitStatuses[habit.id] ?? false)")

        do {
            try modelContext.save()
            print("Changes saved successfully.")
        } catch {
            print("Error saving changes: \(error)")
        }

        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.impactOccurred()
    }

    
    private func ensureAllHabitsIncluded() {
        for habit in habitsForEntry() {
            if entry.habitStatuses[habit.id] == nil {
                entry.habitStatuses[habit.id] = false
            }
        }
        try? modelContext.save()
    }
    
    
}
