//
//  FamilyGateView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/10/25.
//

import Foundation
import SwiftUI

struct FamilyGateView: View {
    let role: UserRole
    
    var body: some View {
        switch role {
        case .organizer: CreateFamilyView()
        case .member: JoinFamilyView()
        }
    }
}

#Preview {
    FamilyGateView(role: .organizer)
}
