//
//  FamilySetupView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/4/25.
//

import SwiftUI

struct FamilySetupView: View {
    let role: UserRole

    var body: some View {
        VStack(spacing: 20) {
            Text("Family Setup")
                .font(.title)
                .bold()

            Text("Will you be creating a family or joining one?")
                .multilineTextAlignment(.center)

            NavigationLink("Create a New Family") {
                CreateFamilyView()
            }
            .buttonStyle(.borderedProminent)

            NavigationLink("Join Existing Family") {
                JoinFamilyView()
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
        .navigationTitle("Family Setup")
    }
}

#Preview {
    NavigationStack {
        FamilySetupView(role: .parent)
    }
}
