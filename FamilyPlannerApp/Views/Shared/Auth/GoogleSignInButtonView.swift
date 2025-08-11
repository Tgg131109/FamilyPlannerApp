//
//  GoogleSignInButtonView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/10/25.
//

import SwiftUI
import AuthenticationServices

struct GoogleSignInButtonView: View {
    @EnvironmentObject private var session: AppSession
    var body: some View {
        Button {
            // Find top-most controller for presentation
            if let root = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first?.rootViewController {
                Task { await GoogleAuthBridge.shared.signIn(presenting: root) }
            } else {
                session.errorMessage = "Unable to find a presenting controller"
            }
        } label: {
            HStack { Image(systemName: "g.circle"); Text("Continue with Google").bold(); Spacer() }
        }
        .frame(height: 44)
        .buttonStyle(.bordered)
    }
}

#Preview {
    GoogleSignInButtonView()
}
