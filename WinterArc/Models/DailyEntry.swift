//
//  DailyEntry.swift
//  WinterArc
//
//  Created by Hriday Chhabria on 12/28/24.
//

import Foundation
import SwiftData

@Model
final class DailyEntry {
    var id: UUID = UUID()
    var date: Date
    var habitStatuses: [UUID: Bool] // Maps habit IDs to their completion status

    init(date: Date, habitStatuses: [UUID: Bool]) {
        self.date = date
        self.habitStatuses = habitStatuses
    }
}

