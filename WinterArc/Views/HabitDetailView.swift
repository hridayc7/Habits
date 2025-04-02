//
//  HabitDetailView.swift
//  WinterArc
//
//  Created on 4/1/25.
//

import SwiftUI
import SwiftData

struct HabitDetailView: View {
    let habit: Habit
    @Query private var entries: [DailyEntry]
    
    // Time period enum for segmented control
    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case allTime = "All Time"
    }
    
    @State private var selectedPeriod: TimePeriod = .week
    @State private var currentOffset = 0 // For swiping between periods
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Segmented control for time period selection
            Picker("Time Period", selection: $selectedPeriod) {
                ForEach(TimePeriod.allCases, id: \.self) { period in
                    Text(period.rawValue)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .onChange(of: selectedPeriod) { _ in
                // Reset offset when changing periods
                currentOffset = 0
            }
            
            // Completion percentage for the selected period - with system colors
            Text("Completion: \(Int(calculateCompletionPercentage(for: selectedPeriod, offset: currentOffset) * 100))%")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .padding(.horizontal)
            
            // Graph with gesture for swiping
            ZStack {
                // Graph background - using system color scheme
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
                    .frame(height: 250)
                
                // Habit completion graph
                VStack {
                    Text("AVERAGE")
                        .font(.caption)
                        .foregroundColor(Color.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 12)
                        .padding(.top, 8)
                    
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(Int(averageCompletion(for: selectedPeriod, offset: currentOffset) * 100))")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("%")
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 12)
                    
                    Text(periodDateRangeString(for: selectedPeriod, offset: currentOffset))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 12)
                    
                    // Actual graph
                    CompletionGraph(
                        entries: entriesForPeriod(selectedPeriod, offset: currentOffset),
                        habit: habit
                    )
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                }
            }
            .frame(height: 250)
            .padding(.horizontal)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        // Detect left or right swipe
                        if value.translation.width < -50 {
                            // Swipe left (newer period)
                            withAnimation {
                                currentOffset += 1
                            }
                        } else if value.translation.width > 50 {
                            // Swipe right (older period)
                            withAnimation {
                                currentOffset -= 1
                            }
                        }
                    }
            )
            
            // Current streak and best streak with dates - using system colors
            HStack(spacing: 20) {
                VStack(spacing: 5) {
                    Text("\(currentStreak())")
                        .font(.system(size: 40, weight: .bold))
                    Text("Current Streak")
                        .font(.subheadline)
                    if currentStreak() > 0 {
                        Text(formatCurrentStreakDates())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                
                VStack(spacing: 5) {
                    Text("\(bestStreak().count)")
                        .font(.system(size: 40, weight: .bold))
                    Text("Best Streak")
                        .font(.subheadline)
                    if bestStreak().count > 0 {
                        Text(formatBestStreakDates())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical)
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Helper methods for time periods
    private func dateRangeForPeriod(_ period: TimePeriod, offset: Int) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        switch period {
        case .week:
            // Find the most recent Monday (or adjust to your preferred week start)
            var weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
            
            // Apply offset (negative for past weeks, positive for future weeks)
            if let offsetDate = calendar.date(byAdding: .weekOfYear, value: -offset, to: weekStart) {
                weekStart = offsetDate
            }
            
            // Week end is 6 days after start
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            return (weekStart, weekEnd)
            
        case .month:
            // First day of current month
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
            
            // Apply offset (negative for past months, positive for future months)
            let offsetMonthStart = calendar.date(byAdding: .month, value: -offset, to: monthStart)!
            
            // Last day of this month
            let offsetMonthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: offsetMonthStart)!
            
            return (offsetMonthStart, offsetMonthEnd)
            
        case .year:
            // First day of current year
            let yearStart = calendar.date(from: calendar.dateComponents([.year], from: today))!
            
            // Apply offset (negative for past years, positive for future years)
            let offsetYearStart = calendar.date(byAdding: .year, value: -offset, to: yearStart)!
            
            // Last day of this year
            let offsetYearEnd = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: offsetYearStart)!
            
            return (offsetYearStart, offsetYearEnd)
            
        case .allTime:
            // For all time, start from habit creation date
            let habitStart = calendar.startOfDay(for: habit.creationDate)
            return (habitStart, today)
        }
    }
    
    // Format the date range as a string for display
    private func periodDateRangeString(for period: TimePeriod, offset: Int) -> String {
        let dateRange = dateRangeForPeriod(period, offset: offset)
        let formatter = DateFormatter()
        
        switch period {
        case .week, .month:
            formatter.dateFormat = "MMM yyyy"
            return formatter.string(from: dateRange.start)
        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: dateRange.start)
        case .allTime:
            formatter.dateFormat = "MMM yyyy"
            return "\(formatter.string(from: dateRange.start))–\(formatter.string(from: dateRange.end))"
        }
    }
    
    // Get entries for a specific time period
    private func entriesForPeriod(_ period: TimePeriod, offset: Int) -> [(date: Date, completed: Bool)] {
        let calendar = Calendar.current
        let dateRange = dateRangeForPeriod(period, offset: offset)
        
        // Generate all dates in the range
        var currentDate = dateRange.start
        var allDates: [Date] = []
        
        while currentDate <= dateRange.end {
            allDates.append(currentDate)
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }
        
        // Map each date to its completion status
        return allDates.map { date in
            let entry = entries.first(where: { calendar.isDate($0.date, inSameDayAs: date) })
            let completed = entry?.habitStatuses[habit.id] ?? false
            return (date: date, completed: completed)
        }
    }
    
    // Calculate completion percentage for a specific period
    private func calculateCompletionPercentage(for period: TimePeriod, offset: Int) -> Double {
        let entriesWithStatus = entriesForPeriod(period, offset: offset)
        
        let totalEntries = entriesWithStatus.count
        let completedEntries = entriesWithStatus.filter { $0.completed }.count
        
        return totalEntries > 0 ? Double(completedEntries) / Double(totalEntries) : 0.0
    }
    
    // Calculate average completion for the graph header
    private func averageCompletion(for period: TimePeriod, offset: Int) -> Double {
        return calculateCompletionPercentage(for: period, offset: offset)
    }
    
    // Function to calculate current streak and return the start date
    private func currentStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Sort entries by date in descending order (newest first)
        let sortedEntries = entries
            .filter { entry in
                let entryDate = calendar.startOfDay(for: entry.date)
                return entryDate <= today &&
                       (calendar.isDate(habit.creationDate, inSameDayAs: entry.date) ||
                        entry.date >= habit.creationDate)
            }
            .sorted { $0.date > $1.date }
        
        var streak = 0
        var currentDate = today
        
        for entry in sortedEntries {
            let entryDate = calendar.startOfDay(for: entry.date)
            
            // Check if this entry is for the expected date
            if calendar.isDate(entryDate, inSameDayAs: currentDate) {
                // If habit was completed, increment streak
                if entry.habitStatuses[habit.id] == true {
                    streak += 1
                    // Move to the previous day for the next iteration
                    if let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) {
                        currentDate = previousDate
                    }
                } else {
                    // Streak broken
                    break
                }
            } else if entryDate < currentDate {
                // There's a gap in the entries - streak is broken
                break
            }
        }
        
        return streak
    }
    
    // Calculate the start date of the current streak
    private func currentStreakStartDate() -> Date? {
        let streak = currentStreak()
        if streak <= 0 {
            return nil
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Go back streak-1 days from today
        return calendar.date(byAdding: .day, value: -(streak - 1), to: today)
    }
    
    // Format the date range for current streak
    private func formatCurrentStreakDates() -> String {
        guard let startDate = currentStreakStartDate(), currentStreak() > 0 else {
            return ""
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        let today = Date()
        return "\(dateFormatter.string(from: startDate)) - Today"
    }
    
    // Format the date range for best streak
    private func formatBestStreakDates() -> String {
        let bestStreakInfo = bestStreak()
        
        if bestStreakInfo.count <= 0 {
            return ""
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        let startStr = dateFormatter.string(from: bestStreakInfo.startDate)
        let endStr = dateFormatter.string(from: bestStreakInfo.endDate)
        
        return "\(startStr) - \(endStr)"
    }
    
    // Function to calculate best streak with date range
    private func bestStreak() -> (count: Int, startDate: Date, endDate: Date) {
        let calendar = Calendar.current
        
        // Sort entries by date in ascending order
        let sortedEntries = entries
            .filter { entry in
                calendar.isDate(habit.creationDate, inSameDayAs: entry.date) ||
                entry.date >= habit.creationDate
            }
            .sorted { $0.date < $1.date }
        
        var currentStreak = 0
        var bestStreak = 0
        var currentStartDate: Date?
        var bestStartDate: Date?
        var bestEndDate: Date?
        var previousDate: Date?
        
        for entry in sortedEntries {
            let entryDate = calendar.startOfDay(for: entry.date)
            
            // Check for continuity
            if let prevDate = previousDate {
                let dayDifference = calendar.dateComponents([.day], from: prevDate, to: entryDate).day ?? 0
                if dayDifference > 1 {
                    // Reset streak if there's a gap (should not happen with your new feature)
                    currentStreak = 0
                    currentStartDate = nil
                }
            }
            
            if entry.habitStatuses[habit.id] == true {
                // If this is a new streak, record the start date
                if currentStreak == 0 {
                    currentStartDate = entryDate
                }
                
                currentStreak += 1
                
                if currentStreak > bestStreak {
                    bestStreak = currentStreak
                    bestStartDate = currentStartDate
                    bestEndDate = entryDate
                }
            } else {
                // Reset the streak
                currentStreak = 0
                currentStartDate = nil
            }
            
            previousDate = entryDate
        }
        
        // Check if current streak is ongoing and is the best streak
        let currentStreakValue = currentStreak
        if currentStreakValue > bestStreak && currentStreakValue > 0 {
            let today = calendar.startOfDay(for: Date())
            if let startDate = currentStreakStartDate() {
                return (
                    count: currentStreakValue,
                    startDate: startDate,
                    endDate: today
                )
            }
        }
        
        return (
            count: bestStreak,
            startDate: bestStartDate ?? Date(),
            endDate: bestEndDate ?? Date()
        )
    }
}

// Preview provider
struct HabitDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HabitDetailView(habit: Habit(name: "Read a Book", creationDate: Date()))
        }
    }
}
