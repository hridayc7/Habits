//
//  HabitsPage.swift
//  WinterArc
//
//  Created by Hriday Chhabria on 12/28/24.
//

import Foundation
import SwiftUI
import SwiftData

struct HabitsPage: View {
    @Query private var habits: [Habit]
    @Query private var entries: [DailyEntry]
    @Environment(\.modelContext) private var modelContext
    @State private var newHabitName: String = ""

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(habits) { habit in
                        Text(habit.name)
                    }
                    .onDelete(perform: deleteHabit)
                }

                VStack {
                    TextField("New Habit Name", text: $newHabitName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button("Add Habit") {
                        guard !newHabitName.isEmpty else { return }
                        addHabit(name: newHabitName)
                        newHabitName = ""
                        dismissKeyboard()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Habits")
        }
    }

    private func addHabit(name: String) {
        let newHabit = Habit(name: name, creationDate: Date())
        modelContext.insert(newHabit)
        try? modelContext.save()
    }

    private func deleteHabit(at offsets: IndexSet) {
        for index in offsets {
            let habitToDelete = habits[index]
            
            for entry in entries {
                entry.habitStatuses.removeValue(forKey: habitToDelete.id)
            }
            
            modelContext.delete(habitToDelete)
        }
        
        try? modelContext.save()
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
