//
//  SignUpViewModel.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/4/25.
//

import Foundation

class SignUpViewModel: ObservableObject {
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var role: UserRole = .organizer
    @Published var errorMessage: String?
    
    var isFormValid: Bool {
        !fullName.isEmpty && !email.isEmpty && password.count >= 6
    }
    
    func createAccount() async -> Bool {
        do {
            let uid = try await FirebaseAuthService.shared.signUp(email: email, password: password)
            print("✅ Created user: \(uid)")
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

// Enum for user roles
enum UserRole: String, CaseIterable {
    case organizer
    case member
    
    var displayName: String {
        switch self {
        case .organizer: return "Organizer"
        case .member: return "Member"
        }
    }
    
    var description: String {
        switch self {
        case .organizer: return "You will create a new family."
        case .member: return "You will join an existing family using a code."
        }
    }
}
