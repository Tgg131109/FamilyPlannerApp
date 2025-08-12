//
//  ManageMembersSheet.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/12/25.
//

import SwiftUI

struct ManageMembersSheet: View {
    let family: FamilyModel
    let currentUserId: String
    let onRemove: (String) -> Void
    let onLeave: () -> Void
    
    var body: some View {
        NavigationStack {
            List {
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
                    }
                }
            }
            .navigationTitle("Manage Members")
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

#Preview("ManageMembers — Organizer view") {
    ManageMembersSheet(
        family: .demoFamily,
        currentUserId: "user-1",  // organizer
        onRemove: { memberId in
            print("Preview remove member:", memberId)
        },
        onLeave: {
            print("Preview leave tapped")
        }
    )
}

#Preview("ManageMembers — Member view") {
    ManageMembersSheet(
        family: .demoFamily,
        currentUserId: "user-2", // regular member
        onRemove: { memberId in
            print("Preview remove member:", memberId)
        },
        onLeave: {
            print("Preview leave tapped")
        }
    )
}
