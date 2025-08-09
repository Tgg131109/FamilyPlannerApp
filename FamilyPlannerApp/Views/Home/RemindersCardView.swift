//
//  RemindersCardView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/7/25.
//

import SwiftUI

struct RemindersCardView: View {
    var body: some View {
        VStack{
            HStack {
                // Icon with circular colored background
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color.red.opacity(0.5))
                    .cornerRadius(6)
                
                // Title text
                Text("Reminders:")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer() // Pushes the content to the left
            }
            
            Divider()
            
            Text("No reminders for today")
                .italic()
        }
        .padding()
        .background(Color(.systemGray6)) // Card background
        .cornerRadius(12)
        .shadow(radius: 1) // Subtle shadow for depth
    }
}

#Preview {
    RemindersCardView()
}
