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
        
        HStack(spacing: 0) {
            Text(greeting)
            
            Text(displayName.isEmpty ? "User" : displayName)
                .fontWeight(.semibold)
                .lineLimit(1)
            
            Spacer()
            
            Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
        }
        .padding(.vertical, 4)
        .padding(.horizontal)
        .font(.system(.caption, design: .rounded))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.thinMaterial)
        }
        
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
        HeaderCardView(greeting: "Good afternoon,", displayName: "Toby", familyName: "Casa Gamble")
            .padding()
            .background(AnimatedMeshGradient())
            .previewLayout(.sizeThatFits)
    }
}

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: animateGradient ? [.blue, .purple] : [.red, .orange]),
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}
