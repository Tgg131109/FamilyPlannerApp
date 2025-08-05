//
//  SignUpView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/4/25.
//

import SwiftUI

struct SignUpView: View {
    @StateObject private var viewModel = SignUpViewModel()
    @State private var shouldNavigate = false

    var body: some View {
        VStack(spacing: 20) {
            Picker("Role", selection: $viewModel.role) {
                ForEach(UserRole.allCases, id: \.self) { role in
                    Text(role.displayName).tag(role)
                }
            }
            .pickerStyle(.segmented)

            Text(viewModel.role.description)
                .font(.caption)
                .foregroundColor(.gray)
            
            TextField("Full Name", text: $viewModel.fullName)
                .textFieldStyle(.roundedBorder)

            TextField("Email", text: $viewModel.email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)

            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button("Continue") {
                Task {
                    let success = await viewModel.createAccount()
                    if success {
                        shouldNavigate = true
                    }
                }
            }
            .disabled(!viewModel.isFormValid)
            .buttonStyle(.borderedProminent)
            .font(.title)
            .bold()

            NavigationLink("", destination: PostSignUpView(role: viewModel.role), isActive: $shouldNavigate)
                .hidden()

//            NavigationLink(destination: PostSignUpView(role: viewModel.role)) {
//                Text("Continue")
//                    .font(.title)
//                    .bold()
//            }
//            .disabled(!viewModel.isFormValid)

            Spacer()
        }
        .padding()
        .navigationTitle("Sign Up")
    }
}

#Preview {
    NavigationStack {
        SignUpView()
    }
}
