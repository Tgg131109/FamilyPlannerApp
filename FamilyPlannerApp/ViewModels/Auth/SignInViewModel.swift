//
//  SignInViewModel.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/4/25.
//

//import Foundation
//
//@MainActor
//class SignInViewModel: ObservableObject {
//    // MARK: - Inputs
//    @Published var email: String = ""
//    @Published var password: String = ""
//
//    // MARK: - UI state
//    @Published var isLoading: Bool = false
//    @Published var errorMessage: String?
//
//    // Basic form validity
//    var isFormValid: Bool {
//        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
//        !password.isEmpty
//    }
//
//    /// Signs the user in with FirebaseAuth.
//    /// Returns true on success so the View can route to MainTabView.
//    func signIn() async -> Bool {
//        isLoading = true
//        errorMessage = nil
//        defer { isLoading = false }
//
//        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
//
//        do {
//            _ = try await FirebaseAuthService.shared.signIn(email: e, password: password)
//
//            // (Optional) You could load the user doc here if you want to hydrate session state.
//            // let uid = FirebaseAuthService.shared.currentUserId()!
//            // let user = try await FirestoreService.shared.fetchUser(uid: uid)
//
//            return true
//        } catch {
//            errorMessage = mapAuthError(error)
//            return false
//        }
//    }
//
//    /// Sends a password reset email (no-op if email is blank/invalid).
//    func sendPasswordReset() async {
//        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !e.isEmpty else {
//            errorMessage = "Enter your email to reset your password."
//            return
//        }
//        isLoading = true
//        errorMessage = nil
//        defer { isLoading = false }
//
//        do {
//            try await FirebaseAuthService.shared.sendPasswordReset(email: e)
//            errorMessage = "Check your inbox for reset instructions."
//        } catch {
//            errorMessage = mapAuthError(error)
//        }
//    }
//
//    // Friendly Firebase error strings
//    private func mapAuthError(_ error: Error) -> String {
//        let ns = error as NSError
//        // Common FirebaseAuth codes; fall back to localizedDescription
//        switch ns.code {
//        case 17008: return "That email address is invalid."
//        case 17009: return "Incorrect password. Try again."
//        case 17011: return "No account found with that email."
//        case 17010: return "Too many attempts. Please wait a moment."
//        case 17020: return "Network error. Check your connection."
//        default:    return ns.localizedDescription
//        }
//    }
//}
