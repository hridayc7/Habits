//
//  CalendarView.swift
//  WinterArc
//
//  Created by Hriday Chhabria on 12/29/24.
//  Updated for scrolling months and correct grid alignment
//

import SwiftUI
import SwiftData

// Extend Date to conform to Identifiable
extension Date: Identifiable {
    public var id: TimeInterval { self.timeIntervalSince1970 }
}

struct CalendarView: View {
    @Query private var entries: [DailyEntry]
    @Query private var habits: [Habit]
    @Environment(\.dismiss) private var dismiss

    // Start from February 2025 (0 represents Dec 2024, 1 -> Jan 2025, 2 -> Feb 2025)
    @State private var currentMonthOffset: Int = 2
    @State private var selectedDate: Date? = nil

    // Seven columns for the days of the week
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        NavigationView {
            VStack {
                // Month navigation bar
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(currentMonthOffset == 0 ? .gray : .blue)
                    }
                    .disabled(currentMonthOffset == 0) // Disable when at Dec 2024
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    Text(currentMonthYear())
                        .font(.title3)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal)
                Spacer().frame(height: 10)
                
                // Weekday header (Monday to Sunday)
                HStack {
                    ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                        Text(day)
                            .frame(maxWidth: .infinity)
                            .font(.caption)
                    }
                }
                .padding(.horizontal)
                
                // Calendar grid
                ScrollViewReader { scrollView in
                    ScrollView(.vertical) {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(generateMonthDates(), id: \.self) { date in
                                if let date = date {
                                    // A cell with a valid date
                                    Group {
                                        if let progress = calculateProgress(for: date) {
                                            CircularProgressRing(progress: progress)
                                                .frame(width: 40, height: 40)
                                                .overlay(
                                                    Text("\(Calendar.current.component(.day, from: date))")
                                                        .font(.caption)
                                                )
                                        } else {
                                            // Even if no progress ring, display the day number
                                            Text("\(Calendar.current.component(.day, from: date))")
                                                .frame(width: 40, height: 40)
                                        }
                                    }
                                    .onTapGesture {
                                        selectedDate = date
                                    }
                                } else {
                                    // Blank cell for alignment
                                    Text("")
                                        .frame(width: 40, height: 40)
                                }
                            }
                        }
                        .padding()
                        .id(currentMonthOffset) // So ScrollViewReader can recognize changes
                    }
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            // Present the detail view when a date is selected
            .sheet(item: $selectedDate) { date in
                if let entry = entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                    EntryDetailView(entry: entry)
                } else {
                    EmptyView()
                }
            }
        }
    }
    
    // Returns a formatted string like "January 2025" based on the current offset
    private func currentMonthYear() -> String {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday as first day
        let referenceDate = DateComponents(calendar: calendar, year: 2024, month: 12, day: 1).date!
        guard let adjustedDate = calendar.date(byAdding: .month, value: currentMonthOffset, to: referenceDate) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: adjustedDate)
    }
    
    private func previousMonth() {
        if currentMonthOffset > 0 {
            currentMonthOffset -= 1
        }
    }
    
    private func nextMonth() {
        currentMonthOffset += 1
    }
    
    // Generate an array of optional Date objects for the calendar grid
    private func generateMonthDates() -> [Date?] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday is the first day of the week
        let referenceDate = DateComponents(calendar: calendar, year: 2024, month: 12, day: 1).date!
        guard let startOfMonth = calendar.date(byAdding: .month, value: currentMonthOffset, to: referenceDate)?.startOfMonth else { return [] }
        
        let range = calendar.range(of: .day, in: .month, for: startOfMonth) ?? 1..<31
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let leadingEmpty = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var dates: [Date?] = Array(repeating: nil, count: leadingEmpty)
        
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                dates.append(date)
            }
        }
        
        let trailingEmpty = (7 - (dates.count % 7)) % 7
        dates.append(contentsOf: Array(repeating: nil, count: trailingEmpty))
        
        return dates
    }
    
    private func calculateProgress(for date: Date) -> Double? {
        guard let entry = entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) else { return nil }
        let relevantHabits = habits.filter { $0.creationDate <= date }
        let totalHabits = relevantHabits.count
        let completedHabits = entry.habitStatuses.filter { $0.value }.count
        return totalHabits > 0 ? Double(completedHabits) / Double(totalHabits) : nil
    }
}

extension Date {
    var startOfMonth: Date? {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self))
    }
}

// Circular Progress Ring for Habit Completion
struct CircularProgressRing: View {
    let progress: Double
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(gradient: Gradient(colors: [Color.blue, Color.green]),
                                   startPoint: .leading,
                                   endPoint: .trailing),
                    lineWidth: 4
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
    }
}


// Preview
struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}
