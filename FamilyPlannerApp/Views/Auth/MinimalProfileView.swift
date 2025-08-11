//
//  MinimalProfileView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/10/25.
//

import Foundation
import SwiftUI

struct MinimalProfileView: View {
    @EnvironmentObject private var session: AppSession
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Setting up your profile…")
        }
        .task {
            await session.start()
        }
    }
}

#Preview {
    MinimalProfileView().environmentObject(AppSession())
}
