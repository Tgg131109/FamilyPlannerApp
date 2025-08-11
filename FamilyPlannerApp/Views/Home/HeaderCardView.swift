//
//  HeaderCardView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/9/25.
//

import SwiftUI

/// A simple header that greets the current user and shows the active family.
/// Reads from SessionManager injected at the app root.
struct HeaderCardView: View {
    let greeting: String
    let displayName: String
    let familyName: String
    
    var body: some View {
        //        CardContainer {
        VStack(alignment: .leading, spacing: 8) {
            HStack{
                Text(greeting)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "house")
                    
                    Text(familyName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
//                .padding(.top, 2)
            }
            
            Text(displayName.isEmpty ? "User" : displayName)
                .font(.largeTitle)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
//            HStack(spacing: 8) {
//                Image(systemName: "house")
//                
//                Text(familyName)
//                    .font(.subheadline)
//                    .foregroundStyle(.secondary)
//                    .lineLimit(1)
//                    .minimumScaleFactor(0.8)
//            }
//            .padding(.top, 2)
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        
        .background(LinearGradient(colors: [Color.blue.opacity(0.35), Color.indigo.opacity(0.35)],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing).ignoresSafeArea(.all, edges: .top))
//        .background(
//            // Subtle card background
//            RoundedRectangle(cornerRadius: 16, style: .continuous)
//                .fill(Color(.secondarySystemBackground))
//        )
//        .overlay(
//            RoundedRectangle(cornerRadius: 16, style: .continuous)
//                .strokeBorder(Color(.separator), lineWidth: 0.5)
//        )
    }
}

struct HeaderCardView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderCardView(greeting: "Good afternoon", displayName: "Toby", familyName: "Casa Gamble")
//            .padding()
//            .background(Color(.systemBackground))
//            .previewLayout(.sizeThatFits)
    }
}
