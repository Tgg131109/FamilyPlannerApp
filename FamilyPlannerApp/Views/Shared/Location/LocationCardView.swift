//
//  LocationCardView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/12/25.
//

import SwiftUI

struct LocationCardView: View {
    let ns: Namespace.ID
    let isSource: Bool
    let action: () -> Void
    
    var body: some View {
        ZStack {
            MembersMapView()
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .matchedGeometryEffect(id: "mapHero", in: ns, isSource: isSource)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 200)
        .shadow(radius: 1)
        .onTapGesture(perform: action)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @Namespace var mapHeroNS
        
        var body: some View {
            LocationCardView(ns: mapHeroNS, isSource: true, action: {})
                .environmentObject(AppSession())
                .padding()
        }
    }
    
    return PreviewWrapper()
}
