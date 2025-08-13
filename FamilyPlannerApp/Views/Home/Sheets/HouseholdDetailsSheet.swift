//
//  HouseholdDetailsSheet.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/12/25.
//

import SwiftUI

struct HouseholdDetailsSheet: View {
    @EnvironmentObject private var session: AppSession
    
    let family: FamilyModel
    let currentUserId: String
    let onRemove: (String) -> Void
    let onLeave: () -> Void
    
    var body: some View {
        NavigationStack {
//            List {
//                
//                
//                Section("Account") {
//                    Button("Sign Out") {
//                        session.signOut()
//                    }
//                }
//            }
//            .frame(height: 200)
            List {
                if let family = session.familyDoc,
                   let fid = family.id {
                    Section("Family") {
                        LabeledContent("Name", value: family.name)
                        LabeledContent("Family ID", value: fid)
                        LabeledContent("Join Code", value: family.joinCode)
                        LabeledContent("Members", value: String(family.members.count))
                    }
                }
                
                Section("Members") {
                    ForEach(memberRows, id: \.id) { m in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(m.displayName ?? m.id)
                                Text(m.role.rawValue.capitalized)
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if canRemove(m) {
                                Button(role: .destructive) { onRemove(m.id) } label: { Text("Remove") }
                            }
                        }
                    }
                }
                
                Section {
                    if canLeave {
                        Button(role: .destructive) { onLeave() } label: { Text("Leave Household") }
                    } else {
                        InviteSheet(
                            familyName: session.familyDoc?.name ?? "",
                            joinCode: session.familyDoc?.joinCode ?? "",
                            onCopy: { UIPasteboard.general.string = session.familyDoc?.joinCode ?? "" },
                            onShare: {
                                // e.g., ShareLink or custom ActivityView
                            }
                        )
                    }
                }
            }
            .navigationTitle("Household")
        }
    }
    
    private var canLeave: Bool {
        // block leaving if you are the organizer
        return family.organizerId != currentUserId
    }
    private func canRemove(_ m: MemberRow) -> Bool {
        // organizer cannot be removed (simple rule)
        return m.id != family.organizerId && currentUserId == family.organizerId
    }
    
    private var memberRows: [MemberRow] {
        family.members.map { (uid, meta) in
            MemberRow(id: uid, displayName: nil, role: meta.role)
        }.sorted { $0.id < $1.id }
    }
    
    struct MemberRow {
        let id: String
        var displayName: String?
        var role: UserRole
    }
}

#Preview("HouseholdDetails — Organizer view") {
    HouseholdDetailsSheet(
        family: .demoFamily,
        currentUserId: "user-1",  // organizer
        onRemove: { memberId in
            print("Preview remove member:", memberId)
        },
        onLeave: {
            print("Preview leave tapped")
        }
    )
    .environmentObject(AppSession())
}

#Preview("HouseholdDetails — Member view") {
    HouseholdDetailsSheet(
        family: .demoFamily,
        currentUserId: "user-2", // regular member
        onRemove: { memberId in
            print("Preview remove member:", memberId)
        },
        onLeave: {
            print("Preview leave tapped")
        }
    )
    .environmentObject(AppSession())
}
