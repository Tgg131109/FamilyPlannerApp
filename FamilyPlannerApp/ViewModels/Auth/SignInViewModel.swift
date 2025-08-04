//
//  SignInViewModel.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/4/25.
//

import Foundation
import SwiftUI

@MainActor
class SignInViewModel: ObservableObject {
    // Input fields
    @Published var email: String = ""
    @Published var password: String = ""

    // Output state
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Simulate Firebase sign in (stubbed for now)
    func signIn() async {
        isLoading = true
        errorMessage = nil

        // Simulate a network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // TODO: Replace with Firebase Auth logic
        if email == "test@example.com" && password == "password" {
            print("✅ Signed in successfully")
        } else {
            errorMessage = "Invalid email or password"
        }

        isLoading = false
    }
}
