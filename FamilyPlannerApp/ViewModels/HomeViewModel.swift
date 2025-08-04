//
//  HomeViewModel.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/4/25.
//

import Foundation
import SwiftUI

// ViewModel for the Home screen
class HomeViewModel: ObservableObject {
    // Published property so the view updates when username changes
    @Published var username: String = "Toby"  // This would later be pulled from Firebase
    
    // Computed property to return a greeting based on the time of day
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Welcome back"
        }
    }
}
