//
//  HomeToolbarView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/11/25.
//

import SwiftUI
import FirebaseFirestore

struct HomeToolbar: ToolbarContent {
    // Data
    let families: [FamilyListItem]
    let currentFamilyId: String?
    let canInvite: Bool
    let pendingFamilyId: String?
    
    // Actions
    let onSelectFamily: (String) -> Void
    let onNewFamily: () -> Void
    let onManageMembers: () -> Void
    let onInvite: () -> Void
    let onProfile: () -> Void
    let onSettings: () -> Void
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                if families.isEmpty {
                    Text("No households yet").foregroundStyle(.secondary)
                } else {
                    Section("Households") {
                        ForEach(families) { item in
                            Button {
                                onSelectFamily(item.id)
                            } label: {
                                HStack {
                                    Text(item.name)
                                    Spacer()
                                    if item.id == currentFamilyId {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                Button {
                    onManageMembers()
                } label: {
                    Label("Household Details", systemImage: "person.3")
                }
                
                Button {
                    onNewFamily()
                } label: {
                    Label("New Household", systemImage: "plus.circle")
                }
            } label: {
                // Prefer pending id while switching
                let activeId = pendingFamilyId ?? currentFamilyId
                let activeName = families.first(where: { $0.id == activeId })?.name
                
                HStack(spacing: 2) {
                    Text(activeName ?? "Select Household")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .tint(.primary)
                    Image(systemName: "chevron.down")
                        .tint(.secondary)
                        .font(.caption)
                }
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            HStack {
//                if canInvite {
//                    Button {
//                        onInvite()
//                    } label: {
//                        Image(systemName: "person.crop.circle.badge.plus").imageScale(.large)
//                    }
//                    .accessibilityLabel("Invite Members")
//                }
                
                Button("Profile", systemImage: "person.crop.circle") {
                    onProfile()
                }
                .labelStyle(.iconOnly)
                
                Button("Settings", systemImage: "gear") {
                    onSettings()
                }
                .labelStyle(.iconOnly)
            }
        }
    }
}

struct FamilyListItem: Identifiable, Equatable {
    let id: String
    let name: String
}

struct ToolbarView: View {
    @StateObject private var vm = HomeViewModel()
    @EnvironmentObject private var session: AppSession
    @State private var pendingFamilyId: String? = nil
    
    var body: some View {
        NavigationStack {
            Text("Hello, world!")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {
                    HomeToolbar(
                        families: session.userFamilies.map { FamilyListItem(id: $0.id ?? "", name: $0.name) },
                        currentFamilyId: session.familyDoc?.id,
                        canInvite: vm.isOrganizer(session: session),
                        pendingFamilyId: pendingFamilyId,
                        onSelectFamily: { id in
                            withAnimation(.snappy) { pendingFamilyId = id }
                            vm.switchFamily(to: id, session: session) },
                        onNewFamily: { vm.presentNewFamily(session: session) },
                        onManageMembers: { vm.presentManageMembers() },
                        onInvite: { vm.presentInvite() },
                        onProfile: { vm.routeToProfile() },
                        onSettings: { vm.routeToSettings() }
                    )
                })
        }
    }
}

#Preview {
    ToolbarView().environmentObject(AppSession())
}
