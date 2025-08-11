//
//  GoogleAuthBridge.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/10/25.
//

import AuthenticationServices

// Bridges to access AuthService without exposing UI frameworks inside it
@MainActor
final class GoogleAuthBridge {
    static let shared = GoogleAuthBridge()
    private init() {}
    private let service = FirebaseAuthService()
    func signIn(presenting: UIViewController) async { do { try await service.signInWithGoogle(presenting: presenting) } catch { print("Google sign-in error: \(error)") } }
}
