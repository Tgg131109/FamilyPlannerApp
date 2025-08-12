//
//  HomeView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/4/25.
//

import SwiftUI
import CoreLocation
import Combine

struct HomeView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var vm = HomeViewModel
    
    @State private var pendingFamilyId: String? = nil
    @State private var cancellable: AnyCancellable?
    
    @Binding var selectedTab: AppTab
    
    init(session: AppSession, repo: FamilyRepositorying) {
            _vm = StateObject(wrappedValue: HomeViewModel(session: session, repo: repo))
        }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    VStack(spacing : 16) {
                        WeatherCardWithLocationView(greeting: vm.greeting, displayName: vm.displayName, familyName: vm.familyName)
                        
                        RemindersCardView()
                        
                        TodayCardView() {
                            selectedTab = .calendar
                        }
                        
                        LocationCardView() {
                            selectedTab = .location
                        }
                    }
                    .padding(.top)
                }
                .padding(.horizontal)
                
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
                    
                    Section("Account") {
                        Button("Sign Out") {
                            session.signOut()
                        }
                    }
                }
                .frame(height: 200)
            }
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
                    onNewFamily: { vm.presentNewFamily() },
                    onManageMembers: { vm.presentManageMembers() },
                    onInvite: { vm.presentInvite() },
                    onProfile: { vm.routeToProfile() },
                    onSettings: { vm.routeToSettings() }
                )
            })
        }
        .sheet(isPresented: $vm.showManageMembers) {
            if let fam = session.familyDoc, let me = session.userDoc?.id {
                ManageMembersSheet(
                    family: fam,
                    currentUserId: me,
                    onRemove: { uid in vm.removeMember(uid) },
                    onLeave: { vm.leaveFamily() }
                )
            } else {
                Text("No household selected.")
                    .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $vm.showInviteSheet) {
            // Your invite/join-code UI
            InviteSheet(
                familyName: session.familyDoc?.name ?? "",
                joinCode: session.familyDoc?.joinCode ?? "",
                onCopy: { UIPasteboard.general.string = session.familyDoc?.joinCode ?? "" },
                onShare: {
                    // e.g., ShareLink or custom ActivityView
                }
            )
        }
        .alert("Error", isPresented: .constant(vm.lastError != nil)) {
            Button("OK") { vm.lastError = nil }
        } message: {
            Text(vm.lastError ?? "")
        }
        .onAppear {
            print("Home appeared")
            // one combined stream, deduped, triggers header refresh
            cancellable = Publishers.CombineLatest(session.$userDoc, session.$familyDoc)
                .removeDuplicates { lhs, rhs in
                    lhs.0?.id == rhs.0?.id && lhs.1?.id == rhs.1?.id
                }
                .sink { _, _ in
                    vm.refreshHeader(session: session)
                }
        }
        .onDisappear {
            cancellable?.cancel()
        }
        .onChange(of: session.familyDoc?.id) { oldValue, newValue in
            if let newValue, newValue == pendingFamilyId {
                pendingFamilyId = nil
            }
            
            if let fid = newValue {
                session.subscribeToMemberLocations(for: fid)
            } else {
                session.stopMemberLocations()
            }
        }
    }
}

#Preview {
    HomeView(selectedTab: .constant(.home))
        .environmentObject(AppSession())
        .environmentObject(GlobalLocationCoordinator.preview())
}
