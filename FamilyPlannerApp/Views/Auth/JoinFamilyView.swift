//
//  JoinFamilyView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/4/25.
//

import SwiftUI

struct JoinFamilyView: View {
    @State private var inviteCode: String = ""
    @State private var joinSuccess: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Join a Family")
                .font(.title2)
                .bold()

            TextField("Enter Invite Code", text: $inviteCode)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.allCharacters)

            Button("Join Family") {
                // TODO: Validate invite code and join family
                if inviteCode.uppercased() == "ABC123" {
                    joinSuccess = true
                }
            }
            .disabled(inviteCode.isEmpty)
            .buttonStyle(.borderedProminent)

            if joinSuccess {
                Text("✅ Successfully joined!")
                    .foregroundColor(.green)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Join Family")
    }
}

#Preview {
    NavigationStack {
        JoinFamilyView()
    }
}
