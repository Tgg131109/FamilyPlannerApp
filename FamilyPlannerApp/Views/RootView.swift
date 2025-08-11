//
//  RootView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/10/25.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        Group {
            switch session.route {
            case .splash: SplashView()
            case .signedOut: WelcomeView()
            case .signedInNoProfile: MinimalProfileView()
            case .needsFamilySetup(let role): FamilyGateView(role: role)
            case .pendingMembership: PendingView()
            case .active: MainTabView()
            }
        }
        .overlay(alignment: .top) {
            if let msg = session.errorMessage { ToastView(text: msg) }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppSession())
        .environmentObject(GlobalLocationCoordinator.preview())
}
