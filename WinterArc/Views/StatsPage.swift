import SwiftUI
import Foundation
import SwiftData
import UniformTypeIdentifiers

struct StatsPage: View {
    @Query private var habits: [Habit]
    @Query private var entries: [DailyEntry]

    var body: some View {
        NavigationView {
            List {
                ForEach(habits) { habit in
                    NavigationLink(destination: HabitDetailView(habit: habit)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(habit.name)
                                .font(.headline)

                            ProgressView(value: calculateCompletion(for: habit))

                            HStack {
                                Text("Streak: \(calculateCurrentStreak(for: habit)) \(calculateCurrentStreak(for: habit) == 1 ? "day" : "days")")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("Completion: \(Int(calculateCompletion(for: habit) * 100))%")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Stats")
        }
    }

    private func calculateCompletion(for habit: Habit) -> Double {
        let relevantEntries = entries.filter { Calendar.current.isDate(habit.creationDate, inSameDayAs: $0.date) || $0.date >= habit.creationDate }
        let totalDays = relevantEntries.count
        let completedDays = relevantEntries.filter { $0.habitStatuses[habit.id] == true }.count
        return totalDays > 0 ? Double(completedDays) / Double(totalDays) : 0
    }

    private func calculateCurrentStreak(for habit: Habit) -> Int {
        let sortedEntries = entries
            .filter {
                Calendar.current.isDate(habit.creationDate, inSameDayAs: $0.date) || $0.date >= habit.creationDate
            }
            .sorted { $0.date < $1.date }

        var currentStreak = 0
        let today = Date()

        for entry in sortedEntries.reversed() {
            if Calendar.current.isDate(entry.date, inSameDayAs: today) { continue }
            if entry.habitStatuses[habit.id] == true {
                currentStreak += 1
            } else {
                break
            }
        }

        if let todayEntry = sortedEntries.last, Calendar.current.isDate(todayEntry.date, inSameDayAs: today),
           todayEntry.habitStatuses[habit.id] == true {
            currentStreak += 1
        }

        return currentStreak
    }
}
