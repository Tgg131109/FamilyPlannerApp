//
//  SignInWithAppleButtonView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/10/25.
//

import SwiftUI
import AuthenticationServices

struct SignInWithAppleButtonView: View {
    @EnvironmentObject private var session: AppSession
    @State private var nonce = FirebaseAuthService.randomNonceString()

    var body: some View {
        SignInWithAppleButton(.signIn) { req in
            req.requestedScopes = [.fullName, .email]
            let hashed = FirebaseAuthService.sha256(nonce)
            req.nonce = hashed
        } onCompletion: { result in
            switch result {
            case .success(let auth):
                if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                    Task {
                        // Pipe the credential to AuthService via AppSession helper
                        await AppleAuthBridge.shared.handle(credential: credential)
                    }
                }
            case .failure(let error):
                session.errorMessage = error.localizedDescription
            }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 44)
        .onAppear { nonce = FirebaseAuthService.randomNonceString() }
    }
}

#Preview {
    SignInWithAppleButtonView()
}
