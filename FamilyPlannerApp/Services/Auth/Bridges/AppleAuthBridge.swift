//
//  AppleAuthBridge.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/10/25.
//

import AuthenticationServices

// Bridges to access AuthService without exposing UI frameworks inside it
@MainActor
final class AppleAuthBridge {
    static let shared = AppleAuthBridge()
    private init() {}
    private let service = FirebaseAuthService()
    func handle(credential: ASAuthorizationAppleIDCredential) async { do { try await service.handleAppleCredential(credential); } catch { print("Apple sign-in error: \(error)") } }
}
