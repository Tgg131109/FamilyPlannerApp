//
//  SplashView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/10/25.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                Text("Loading…").foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SplashView()
}
