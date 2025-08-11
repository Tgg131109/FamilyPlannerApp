//
//  ReminderModel.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/10/25.
//

import Foundation

/// A single reminder shown on the Home screen.
/// Replace with your real Reminder domain model when ready.
public struct ReminderItem: Identifiable, Equatable {
    public let id: String
    public var title: String
    public var due: Date?
    public var isCompleted: Bool

    public init(id: String, title: String, due: Date?, isCompleted: Bool) {
        self.id = id
        self.title = title
        self.due = due
        self.isCompleted = isCompleted
    }
}
