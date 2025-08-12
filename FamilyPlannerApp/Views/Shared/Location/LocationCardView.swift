//
//  LocationCardView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/12/25.
//

import SwiftUI

struct LocationCardView: View {
    let action: () -> Void
    
    var body: some View {
        ZStack {
            MembersMapView()
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 120)
        .shadow(radius: 1)
        .onTapGesture(perform: action)
    }
}

#Preview {
    LocationCardView(action: {})
        .environmentObject(AppSession())
        .padding()
}
