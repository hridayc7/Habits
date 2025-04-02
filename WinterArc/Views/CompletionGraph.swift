//
//  CompletionGraph.swift
//  WinterArc
//
//  Created on 4/1/25.
//

import SwiftUI

struct CompletionGraph: View {
    let entries: [(date: Date, completed: Bool)]
    let habit: Habit
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid lines
                VStack(spacing: 0) {
                    ForEach(0..<4) { i in
                        Divider()
                            .background(Color.secondary.opacity(0.3))
                            .frame(height: 1)
                        if i < 3 {
                            Spacer()
                        }
                    }
                }
                
                // Chart lines
                if !entries.isEmpty {
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        let stepWidth = width / CGFloat(entries.count - 1 > 0 ? entries.count - 1 : 1)
                        
                        // Start at the first point
                        let firstPoint = CGPoint(
                            x: 0,
                            y: entries.first?.completed == true ? height * 0.3 : height * 0.7
                        )
                        path.move(to: firstPoint)
                        
                        // Draw lines to each point
                        for i in 1..<entries.count {
                            let point = CGPoint(
                                x: stepWidth * CGFloat(i),
                                y: entries[i].completed ? height * 0.3 : height * 0.7
                            )
                            path.addLine(to: point)
                        }
                    }
                    .stroke(Color.accentColor, lineWidth: 2)
                    
                    // Add circles at data points
                    ForEach(0..<entries.count, id: \.self) { i in
                        Circle()
                            .fill(entries[i].completed ? Color.accentColor : Color.secondary)
                            .frame(width: 6, height: 6)
                            .position(
                                x: geometry.size.width / CGFloat(entries.count - 1 > 0 ? entries.count - 1 : 1) * CGFloat(i),
                                y: entries[i].completed ? geometry.size.height * 0.3 : geometry.size.height * 0.7
                            )
                    }
                    
                    // Add month indicators at bottom
                    HStack(spacing: 0) {
                        ForEach(monthLabels(), id: \.self) { label in
                            Text(label)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(width: geometry.size.width, height: 20)
                    .position(x: geometry.size.width / 2, y: geometry.size.height - 10)
                } else {
                    Text("No data available")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
    
    // Generate month labels for the x-axis
    private func monthLabels() -> [String] {
        let calendar = Calendar.current
        let monthSymbols = calendar.shortMonthSymbols
        
        if entries.count <= 7 {
            // For week view, use days of week
            return entries.map { entry in
                let day = calendar.component(.day, from: entry.date)
                return "\(day)"
            }
        } else if entries.count <= 31 {
            // For month view, show day numbers for every few days
            let interval = max(entries.count / 5, 1)
            return entries.enumerated().compactMap { index, entry in
                if index % interval == 0 {
                    let day = calendar.component(.day, from: entry.date)
                    return "\(day)"
                }
                return " "
            }
        } else {
            // For year/all-time, show month abbreviations
            var labels: [String] = []
            var lastMonth = -1
            
            for (index, entry) in entries.enumerated() {
                let month = calendar.component(.month, from: entry.date) - 1 // 0-indexed
                if month != lastMonth {
                    labels.append(String(monthSymbols[month].prefix(1)))
                    lastMonth = month
                } else if index % (entries.count / 12) == 0 {
                    // Add some spacing with empty labels
                    labels.append(" ")
                }
            }
            
            return labels
        }
    }
}
