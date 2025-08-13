//
//  HomeToolbarView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/11/25.
//

import SwiftUI
import FirebaseFirestore

struct HomeToolbar: ToolbarContent {
    let families: [FamilyListItem]
    let currentFamilyId: String?
    //    let canInvite: Bool
    let pendingFamilyId: String?
    let userPhotoURL: String?
    let userDisplayName: String?
    
    // Actions
    let onSelectFamily: (String) -> Void
    let onNewFamily: () -> Void
    let onHouseholdDetails: () -> Void
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
                    onHouseholdDetails()
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
                Button {
                    onProfile()
                } label: {
                    ToolbarAvatar(urlString: userPhotoURL, displayName: userDisplayName, size: 28)
                }
                .accessibilityLabel(userDisplayName ?? "Profile")
                
                //                Button("Profile", systemImage: "person.crop.circle") {
                //                    onProfile()
                //                }
                //                .labelStyle(.iconOnly)
                
                Button("Settings", systemImage: "gear") {
                    onSettings()
                }
                .labelStyle(.iconOnly)
            }
        }
    }
}

struct ToolbarAvatar: View {
    let urlString: String?
    let displayName: String?
    let size: CGFloat
    
    private var initials: String {
        let parts = (displayName ?? "")
            .split(separator: " ")
            .prefix(2)
        let chars = parts.compactMap { $0.first }
        let s = String(chars).uppercased()
        
        return s.isEmpty ? "?" : s
    }
    
    private var initialsBubble: some View {
        Text(initials)
            .font(.system(size: max(12, size * 0.45), weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(.tint)) // uses app accent/tint
    }
    
    var body: some View {
        Group {
            if let s = urlString, let url = URL(string: s) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        ProgressView()
                            .scaleEffect(0.7)
                    case .failure(_):
                        initialsBubble
                    @unknown default:
                        initialsBubble
                    }
                }
            } else {
                initialsBubble
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(.quaternary, lineWidth: 1))
        .contentShape(Circle())
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
                        //                        canInvite: vm.isOrganizer(session: session),
                        pendingFamilyId: pendingFamilyId,
                        userPhotoURL: session.userDoc?.photoURL,
                        userDisplayName: session.userDoc?.displayName,
                        onSelectFamily: { id in
                            withAnimation(.snappy) { pendingFamilyId = id }
                            vm.switchFamily(to: id, session: session) },
                        onNewFamily: { vm.presentNewFamily(session: session) },
                        onHouseholdDetails: { vm.presentHouseholdDetails() },
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
