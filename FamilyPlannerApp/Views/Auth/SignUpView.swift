//
//  SignUpView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/4/25.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var role: UserRole = .organizer
    @State private var busy = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") { TextField("Display name", text: $displayName) }
                Section("Account") { TextField("Email", text: $email).textInputAutocapitalization(.never).keyboardType(.emailAddress); SecureField("Password", text: $password) }
                Section("Role") {
                    Picker("I'm the", selection: $role) {
                        Text("Organizer (creates household)").tag(UserRole.organizer)
                        Text("Member (joins household)").tag(UserRole.member)
                    }
                }
                Section {
                    Button(busy ? "Creating…" : "Create Account") {
                        busy = true
                        Task { await session.signUp(email: email, password: password, displayName: displayName, role: role); busy = false; dismiss() }
                    }.disabled(busy || displayName.isEmpty || email.isEmpty || password.count < 6)
                }
                Section("Or continue with") { SocialButtonsRow() }
            }
            .navigationTitle("Create Account")
        }
    }
    //    @StateObject private var viewModel = SignUpViewModel()
    //    //    @State private var shouldNavigate = false
    //
    //    /// Call this after the Firebase user doc is created successfully.
    //    let onCompleted: (UserRole) -> Void
    //
    //    var body: some View {
    //        VStack(spacing: 20) {
    //            Picker("Role", selection: $viewModel.role) {
    //                ForEach(UserRole.allCases, id: \.self) { role in
    //                    Text(role.displayName).tag(role)
    //                }
    //            }
    //            .pickerStyle(.segmented)
    //
    //            Text(viewModel.role.description)
    //                .font(.caption)
    //                .foregroundColor(.gray)
    //
    //            TextField("Full Name", text: $viewModel.fullName)
    //                .textFieldStyle(.roundedBorder)
    //
    //            TextField("Email", text: $viewModel.email)
    //                .textFieldStyle(.roundedBorder)
    //                .keyboardType(.emailAddress)
    //                .autocapitalization(.none)
    //
    //            SecureField("Password", text: $viewModel.password)
    //                .textFieldStyle(.roundedBorder)
    //
    //
    //            if let error = viewModel.errorMessage {
    //                Text(error)
    //                    .foregroundColor(.red)
    //                    .font(.caption)
    //            }
    //
    //            Button("Continue") {
    //                Task {
    //                    if await viewModel.createAccount() { onCompleted(viewModel.role) }
    //                }
    //            }
    //            .disabled(!viewModel.isFormValid)
    //            .buttonStyle(.borderedProminent)
    //            .font(.title)
    //            .bold()
    //
    //            //            NavigationLink("", destination: PostSignUpView(role: viewModel.role), isActive: $shouldNavigate)
    //            //                .hidden()
    //
    //            //            NavigationLink(destination: PostSignUpView(role: viewModel.role)) {
    //            //                Text("Continue")
    //            //                    .font(.title)
    //            //                    .bold()
    //            //            }
    //            //            .disabled(!viewModel.isFormValid)
    //
    //            Spacer()
    //        }
    //        .padding()
    //        .navigationTitle("Sign Up")
    //        //        // ✅ iOS 16+ way to route imperatively from a boolean
    //        //        .navigationDestination(isPresented: $shouldNavigate) {
    //        //            PostSignUpView(role: viewModel.role)
    //        //        }
    //    }
}

#Preview {
    SignUpView()
}
