//
//  HomeCardView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/4/25.
//

import SwiftUI

// Reusable card-style button for home screen navigation
struct HomeCardView: View {
    let title: String               // Title shown on the card
    let systemImage: String         // SF Symbol icon
    let color: Color                // Icon background color
    let action: () -> Void          // Action triggered when tapped
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Icon with circular colored background
                Image(systemName: systemImage)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .padding()
                    .background(color)
                    .clipShape(Circle())
                
                // Title text
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer() // Pushes the content to the left
            }
            .padding()
            .background(Color(.systemGray6)) // Card background
            .cornerRadius(12)
            .shadow(radius: 1) // Subtle shadow for depth
        }
    }
}

#Preview {
    HomeCardView(title: "Add Family Member", systemImage: "plus", color: .blue, action: {})
}
