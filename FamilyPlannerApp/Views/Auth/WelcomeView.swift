//
//  WelcomeView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/4/25.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Text("👨‍👩‍👧‍👦 Family Planner")
                    .font(.largeTitle)
                    .bold()

                Text("Plan meals, share calendars, keep your family connected.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                NavigationLink("Sign In") {
                    SignInView()
                }
                .buttonStyle(.borderedProminent)

                NavigationLink("Sign Up") {
                    SignUpView()
                }
                .buttonStyle(.bordered)

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    WelcomeView().environmentObject(AppState())
}
