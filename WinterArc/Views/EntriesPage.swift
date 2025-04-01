//
//  EntriesPage.swift
//  WinterArc
//
//  Created by Hriday Chhabria on 12/28/24.
//

import SwiftUI
import Foundation
import SwiftData

struct EntriesPage: View {
    @Query private var habits: [Habit]
    @Query private var entries: [DailyEntry]
    @Environment(\.modelContext) private var modelContext
    @State private var showAlert: Bool = false

    var body: some View {
        NavigationView {
            List {
                ForEach(entries) { entry in
                    NavigationLink(destination: EntryDetailView(entry: entry)) {
                        HStack {
                            Text(entry.date, style: .date)
                            Spacer()
                            Text("Score: \(entry.habitStatuses.filter { $0.value }.count)/\(habits.filter { Calendar.current.isDate($0.creationDate, inSameDayAs: entry.date) || $0.creationDate <= entry.date }.count)")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .onDelete(perform: deleteEntry)
            }
            .navigationTitle("Entries")
            .toolbar {
                Button("New Entry") {
                    createEntry(for: Date())
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Uh-oh ⁉ "), message: Text("You can't create more than one entry for a day. Modify your current daily entry instead."), dismissButton: .default(Text("OK")))
            }
        }
    }
    

    private func createEntry(for date: Date) {
        if entries.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            showAlert = true
            return
        }

        var newEntry = DailyEntry(date: date, habitStatuses: [:])
        for habit in habits where Calendar.current.isDate(habit.creationDate, inSameDayAs: date) || habit.creationDate <= date {
            newEntry.habitStatuses[habit.id] = false
        }
        modelContext.insert(newEntry)
    }
    
    private func deleteEntry(at offsets: IndexSet) {
        for index in offsets {
            let entry = entries[index]
            modelContext.delete(entry)
        }
        do {
            try modelContext.save()
            print("Entry successfully deleted.")
        } catch {
            print("Error deleting entry: \(error)")
        }
    }
}
