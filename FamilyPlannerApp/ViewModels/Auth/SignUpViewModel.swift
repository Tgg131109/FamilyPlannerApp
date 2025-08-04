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
    @Published var role: UserRole = .parent
    @Published var errorMessage: String?

    var isFormValid: Bool {
        !fullName.isEmpty && !email.isEmpty && password.count >= 6
    }
}

// Enum for user roles
enum UserRole: String, CaseIterable {
    case parent
    case child

    var displayName: String {
        switch self {
        case .parent: return "Parent"
        case .child: return "Child"
        }
    }
}
