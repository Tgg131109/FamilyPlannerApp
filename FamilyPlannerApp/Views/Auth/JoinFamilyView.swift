//
//  JoinFamilyView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/4/25.
//

import SwiftUI

struct JoinFamilyView: View {
    @EnvironmentObject private var session: AppSession
    @State private var code = ""
    @State private var busy = false
    
    var body: some View {
        Form {
            Section("Enter Code") {
                TextField("JOINCODE", text: $code).textInputAutocapitalization(.characters)
            }
            
            Section {
                Button(busy ? "Joining…" : "Join Family") {
                    busy = true
                    
                    Task {
                        await session.joinFamily(joinCode: code)
                        
                        busy = false
                    }
                }
                .disabled(busy || code.count < 4)
            }
        }
        .navigationTitle("Join Family")
    }
}

//struct JoinFamilyView: View {
//    @State private var inviteCode: String = ""
//    @State private var joinSuccess: Bool = false
//
//    var body: some View {
//        VStack(spacing: 20) {
//            Text("Join a Family")
//                .font(.title2)
//                .bold()
//
//            TextField("Enter Invite Code", text: $inviteCode)
//                .textFieldStyle(.roundedBorder)
//                .autocapitalization(.allCharacters)
//
//            Button("Join Family") {
//                // TODO: Validate invite code and join family
//                if inviteCode.uppercased() == "ABC123" {
//                    joinSuccess = true
//                }
//            }
//            .disabled(inviteCode.isEmpty)
//            .buttonStyle(.borderedProminent)
//
//            if joinSuccess {
//                Text("✅ Successfully joined!")
//                    .foregroundColor(.green)
//            }
//
//            Spacer()
//        }
//        .padding()
//        .navigationTitle("Join Family")
//    }
//}

#Preview {
    NavigationStack {
        JoinFamilyView().environmentObject(AppSession())
    }
}
