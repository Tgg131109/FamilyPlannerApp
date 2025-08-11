//
//  CreateFamilyView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/4/25.
//

import SwiftUI

struct CreateFamilyView: View {
    @EnvironmentObject private var session: AppSession
    @State private var familyName = ""
    @State private var busy = false
    
    var body: some View {
        Form {
            Section("Household Details") {
                TextField("Household name", text: $familyName)
            }
            
            Section {
                Button(busy ? "Creating…" : "Create Household") {
                    busy = true; Task {
                        await session.createFamily(name: familyName)
                        
                        busy = false
                    }
                }
                .disabled(busy || familyName.isEmpty)
            }
        }
        .navigationTitle("Create Household")
    }
}

//struct CreateFamilyView: View {
//    @State private var familyName: String = ""
//    @State private var inviteCode: String? = nil
//
//    var body: some View {
//        VStack(spacing: 20) {
//            Text("Create a Family")
//                .font(.title2)
//                .bold()
//
//            TextField("Family Name", text: $familyName)
//                .textFieldStyle(.roundedBorder)
//
//            Button("Create Family") {
//                // TODO: Call Firebase to create family and get invite code
//                inviteCode = "ABC123"
//            }
//            .disabled(familyName.isEmpty)
//            .buttonStyle(.borderedProminent)
//
//            if let code = inviteCode {
//                Text("Invite Code: \(code)")
//                    .font(.headline)
//                    .padding(.top)
//            }
//
//            Spacer()
//        }
//        .padding()
//        .navigationTitle("Create Family")
//    }
//}

#Preview {
    NavigationStack {
        CreateFamilyView().environmentObject(AppSession())
    }
}
