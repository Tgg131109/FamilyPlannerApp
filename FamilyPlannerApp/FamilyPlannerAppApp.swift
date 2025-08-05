//
//  FamilyPlannerAppApp.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/4/25.
//

import SwiftUI
import Firebase

@main
struct FamilyPlannerMockupApp: App {
    @StateObject private var appState = AppState()

    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            if appState.isSignedIn {
                MainTabView()
                    .environmentObject(appState)
            } else {
                WelcomeView()
                    .environmentObject(appState)
            }
        }
    }
}

