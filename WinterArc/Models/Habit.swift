//
//  Habit.swift
//  WinterArc
//
//  Created by Hriday Chhabria on 12/28/24.
//

import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID = UUID()
    var name: String
    var creationDate: Date

    init(name: String, creationDate: Date) {
        self.name = name
        self.creationDate = creationDate
    }
}
