//
//  TodayCardView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/7/25.
//

import SwiftUI

struct TodayCardView: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                HStack {
                    // Icon with circular colored background
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.teal.opacity(0.5))
                        .cornerRadius(6)
                    
                    // Title text
                    Text("Today")
                        .font(.headline)
                        .tint(.primary)
                    
                    Spacer() // Pushes the content to the left
                }
                
                Divider()
                
                HStack{
                    Text("Events:")
                        .tint(.secondary)
                    
                    Spacer()
                }
                
                Text("No events for today")
                    .italic()
                    .tint(.primary)
            }
            .padding()
            .background(Color(.systemGray6)) // Card background
            .cornerRadius(12)
            .shadow(radius: 1) // Subtle shadow for depth
        }
    }
}

#Preview {
    TodayCardView(action: {})
}
