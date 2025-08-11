//
//  FirebaseAuthService.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/5/25.
//

import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit
import GoogleSignIn
import FirebaseCore

@MainActor
final class FirebaseAuthService: AuthServicing {
    var currentUID: String? { Auth.auth().currentUser?.uid }
    var currentEmail: String? { Auth.auth().currentUser?.email }
    var providerIDs: [String] { Auth.auth().currentUser?.providerData.map { $0.providerID } ?? [] }
    
    func signIn(email: String, password: String) async throws {
        _ = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<AuthDataResult, Error>) in
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error { cont.resume(throwing: error) }
                else if let result = result { cont.resume(returning: result) }
            }
        }
    }
    
    func signUp(email: String, password: String) async throws -> String {
        let result: AuthDataResult = try await withCheckedThrowingContinuation { cont in
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error { cont.resume(throwing: error) }
                else if let result = result { cont.resume(returning: result) }
            }
        }
        return result.user.uid
    }
    
    func signOut() throws { try Auth.auth().signOut() }
    
    // MARK: - Apple
    private var currentNonce: String?
    
    func signInWithApple(nonce: String) async throws {
        self.currentNonce = nonce
        // The Apple flow is initiated from the SwiftUI button; we only receive the credential here.
        // See SignInWithAppleButton representable in Views/AuthButtons.swift
    }
    
    func handleAppleCredential(_ appleIDCredential: ASAuthorizationAppleIDCredential) async throws {
        // Get the raw Apple ID token string
        guard
            let tokenData = appleIDCredential.identityToken,
            let idTokenString = String(data: tokenData, encoding: .utf8)
        else {
            throw NSError(
                domain: "AppleTokenError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to fetch Apple identity token."]
            )
        }

        // Use OAuthProvider.appleCredential (no AppleAuthProvider symbol needed)
        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: currentNonce ?? "",
            fullName: appleIDCredential.fullName // optional; keeps name if provided on first auth
        )

        // Sign into Firebase
        _ = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<AuthDataResult, Error>) in
            Auth.auth().signIn(with: firebaseCredential) { result, error in
                if let error = error { cont.resume(throwing: error) }
                else if let result = result { cont.resume(returning: result) }
            }
        }
    }

    
    // Nonce utilities
    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in UInt8.random(in: 0...255) }
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count { result.append(charset[Int(random)]); remainingLength -= 1 }
            }
        }
        return result
    }
    
    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Google
    func signInWithGoogle(presenting: UIViewController) async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "MissingClientID", code: -1)
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenting)
        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "GoogleIDTokenMissing", code: -1)
        }
        let accessToken = result.user.accessToken.tokenString
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        _ = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<AuthDataResult, Error>) in
            Auth.auth().signIn(with: credential) { result, error in
                if let error = error { cont.resume(throwing: error) }
                else if let result = result { cont.resume(returning: result) }
            }
        }
    }
    
    
    //    static let shared = FirebaseAuthService()
    //
    //    private init() {}
    //
    //    func signUp(email: String, password: String) async throws -> String {
    //        let result = try await Auth.auth().createUser(withEmail: email, password: password)
    //        return result.user.uid
    //    }
    //
    //    func signIn(email: String, password: String) async throws -> String {
    //        let result = try await Auth.auth().signIn(withEmail: email, password: password)
    //        return result.user.uid
    //    }
    //
    //    func updateDisplayName(_ name: String) async throws {
    //        guard let user = Auth.auth().currentUser else { return }
    //        let change = user.createProfileChangeRequest()
    //        change.displayName = name
    //        try await change.commitChanges()
    //    }
    //
    //    func currentUserId() -> String? {
    //        Auth.auth().currentUser?.uid
    //    }
    //
    //    func signOut() throws {
    //        try Auth.auth().signOut()
    //    }
}

extension FirebaseAuthService {
    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
}
