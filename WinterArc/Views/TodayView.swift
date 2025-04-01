import SwiftData
import SwiftUI
import ConfettiSwiftUI

struct TodayView: View {
    @Query private var habits: [Habit]
    @Query private var entries: [DailyEntry]
    @Environment(\ .modelContext) private var modelContext
    @State private var newHabitName: String = ""
    @State private var isCalendarPresented = false
    @State private var confettiCounter = 0

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium // Options: .short, .medium, .long, .full
        formatter.timeStyle = .none  // Options: .none, .short, .medium, .long
        return formatter
    }()

    var body: some View {
        NavigationView {
            VStack {
                if habits.isEmpty {
                    Text("No habits being tracked currently.")
                        .foregroundColor(.gray)
                } else if let todayEntry = entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: Date()) }) {
                    List {
                        ForEach(habitsForEntry(todayEntry)) { habit in
                            HStack {
                                Text(habit.name)
                                Spacer()
                                Button(action: {
                                    toggleHabitStatus(habit, for: todayEntry)
                                    checkCompletion(for: todayEntry)
                                }) {
                                    Image(systemName: todayEntry.habitStatuses[habit.id] == true ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(todayEntry.habitStatuses[habit.id] == true ? .green : .gray)
                                }
                            }
                        }
                    }
                } else {
                    Text("No entry found for today. It will be created automatically.")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Today")
            .onAppear {
                createEntryIfNeeded()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text(Date().formatted(.dateTime.month(.wide).day().year()))
                        .font(.callout)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        print("Calendar Pressed")
                        isCalendarPresented = true
                    } label: {
                        Label("Calendar", systemImage: "calendar")
                    }
                    .sheet(isPresented: $isCalendarPresented) {
                        CalendarView()
                    }
                }
            }
            .overlay(
                ConfettiCannon(trigger: $confettiCounter, num: 120, openingAngle: .degrees(60), radius: 600, repetitions: 1, repetitionInterval: 0.4)
            )
        }
    }

    private func checkCompletion(for entry: DailyEntry) {
        if entry.habitStatuses.values.allSatisfy({ $0 }) {
            withAnimation {
                confettiCounter += 1
            }
        }
    }

    private func createEntryIfNeeded() {
        if let todayEntry = entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: Date()) }) {
            ensureAllHabitsIncluded(for: todayEntry)
        } else {
            createNewEntryForToday()
        }
    }

    private func ensureAllHabitsIncluded(for entry: DailyEntry) {
        for habit in habitsForEntry(entry) {
            if entry.habitStatuses[habit.id] == nil {
                entry.habitStatuses[habit.id] = false
            }
        }
        try? modelContext.save()
    }

    private func createNewEntryForToday() {
        var newEntry = DailyEntry(date: Date(), habitStatuses: [:])

        for habit in habits {
            newEntry.habitStatuses[habit.id] = false
        }

        modelContext.insert(newEntry)
        try? modelContext.save()
    }

    private func habitsForEntry(_ entry: DailyEntry) -> [Habit] {
        habits.filter { Calendar.current.isDate($0.creationDate, inSameDayAs: entry.date) || $0.creationDate <= entry.date }
    }

    private func toggleHabitStatus(_ habit: Habit, for entry: DailyEntry) {
        entry.habitStatuses[habit.id]?.toggle()
        try? modelContext.save()

        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.impactOccurred()
    }
}

#Preview {
    TodayView()
}
