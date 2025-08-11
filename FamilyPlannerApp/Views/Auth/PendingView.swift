//
//  PendingView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/10/25.
//

import Foundation
import SwiftUI

struct PendingView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "hourglass")
            Text("Your membership is pending approval.")
            Text("You'll get access as soon as the organizer approves.").foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    PendingView()
}
