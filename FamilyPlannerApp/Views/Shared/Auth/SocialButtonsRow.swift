//
//  SocialButtonsRow.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/10/25.
//

import SwiftUI
import AuthenticationServices

struct SocialButtonsRow: View {
    var body: some View {
        VStack(spacing: 12) {
            SignInWithAppleButtonView()
            GoogleSignInButtonView()
        }
    }
}

#Preview {
    SocialButtonsRow()
}
