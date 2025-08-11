//
//  SignInView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/4/25.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var busy = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section { TextField("Email", text: $email).textInputAutocapitalization(.never).keyboardType(.emailAddress); SecureField("Password", text: $password) }
                
                Section {
                    Button(busy ? "Signing in…" : "Sign In") {
                        busy = true
                        Task { await session.signIn(email: email, password: password); busy = false; if session.route != .signedOut { dismiss() } }
                    }.disabled(busy || email.isEmpty || password.isEmpty)
                }
                
                Section("Or continue with") { SocialButtonsRow() }
            }
            .navigationTitle("Sign In")
        }
    }
    //    @StateObject private var viewModel = SignInViewModel()
    //    //    @EnvironmentObject var appState: AppState
    //    @StateObject private var session = AppManager()
    //    @Environment(\.dismiss) private var dismiss
    //
    //    var body: some View {
    //        VStack(spacing: 24) {
    //            Text("Sign In")
    //                .font(.largeTitle)
    //                .bold()
    //
    //            // Email Field
    //            TextField("Email", text: $viewModel.email)
    //                .textFieldStyle(.roundedBorder)
    //                .keyboardType(.emailAddress)
    //                .textInputAutocapitalization(.never)
    //                .autocorrectionDisabled(true)
    //
    //            // Password Field
    //            SecureField("Password", text: $viewModel.password)
    //                .textFieldStyle(.roundedBorder)
    //
    //            // Error Message
    //            if let error = viewModel.errorMessage {
    //                Text(error)
    //                    .foregroundColor(.red)
    //                    .font(.caption)
    //            }
    //
    //            // Sign In Button
    //            Button {
    //                Task {
    //                    let ok = await viewModel.signIn()
    //
    //                    if ok {
    //                        // Optional: eagerly load session (Auth listener will do this too)
    //                        await session.loadSession(for: FirebaseAuthService.shared.currentUserId())
    //                        // If this view was presented modally, dismiss it
    //                        dismiss()
    //                    }
    //                }
    //            } label: {
    //                if viewModel.isLoading {
    //                    ProgressView()
    //                } else {
    //                    Text("Sign In")
    //                        .frame(maxWidth: .infinity)
    //                }
    //            }
    //            .buttonStyle(.borderedProminent)
    //            .disabled(!viewModel.isFormValid || viewModel.isLoading)
    //
    //            // Forgot password
    //            Button("Forgot password?") {
    //                Task { await viewModel.sendPasswordReset() }
    //            }
    //            .buttonStyle(.plain)
    //            .font(.footnote)
    //
    //            Spacer()
    //        }
    //        .padding()
    //        .navigationTitle("Sign In")
    //    }
}

#Preview {
    SignInView()
}
