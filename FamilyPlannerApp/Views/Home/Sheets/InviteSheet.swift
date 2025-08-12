//
//  InviteSheet.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/12/25.
//

import SwiftUI

struct InviteSheet: View {
    let familyName: String
    let joinCode: String
    let onCopy: () -> Void
    let onShare: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Invite to \(familyName)").font(.headline)
            Text("Use this code to join:")
            Text(joinCode)
                .font(.system(.title, design: .monospaced).weight(.bold))
                .padding(8)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            HStack {
                Button("Copy") { onCopy() }
                Button("Share…") { onShare() }
            }
        }
        .padding()
    }
}

#Preview {
    InviteSheet(familyName: "Gamble Family", joinCode: "1234567890", onCopy: {}, onShare: {})
}

