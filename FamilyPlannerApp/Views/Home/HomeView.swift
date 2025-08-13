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
    @StateObject private var vm = HomeViewModel()
    
    @State private var pendingFamilyId: String? = nil
    @State private var cancellable: AnyCancellable?
    
    @Binding var selectedTab: AppTab
    
    let repo: FamilyRepositorying
    
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                HomeToolbar(
                    families: session.userFamilies.map { FamilyListItem(id: $0.id ?? "", name: $0.name) },
                    currentFamilyId: session.familyDoc?.id,
                    //                    canInvite: vm.isOrganizer(session: session),
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
        .sheet(isPresented: $vm.showHouseholdDetails) {
            if let fam = session.familyDoc, let me = session.userDoc?.id {
                HouseholdDetailsSheet(
                    family: fam,
                    currentUserId: me,
                    onRemove: { uid in vm.removeMember(uid, session: session, repo: repo) },
                    onLeave: { vm.leaveFamily(session: session, repo: repo) }
                )
            } else {
                Text("No household selected.")
                    .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $vm.showNewFamilySheet) {
            NewFamilySheet(
                name: $vm.newFamilyName,
                isCreating: vm.isCreatingFamily,
                onCancel: { vm.showNewFamilySheet = false },
                onCreate: { vm.createFamily(session: session, repo: repo) }
            )
        }
        .sheet(isPresented: $vm.showProfileSheet) {
            ProfileSheet()
        }
        .alert("Error", isPresented: .constant(vm.createError != nil)) {
            Button("OK") { vm.createError = nil }
        } message: {
            Text(vm.createError ?? "")
        }
        
        //        .sheet(isPresented: $vm.showInviteSheet) {
        //            // Your invite/join-code UI
        //            InviteSheet(
        //                familyName: session.familyDoc?.name ?? "",
        //                joinCode: session.familyDoc?.joinCode ?? "",
        //                onCopy: { UIPasteboard.general.string = session.familyDoc?.joinCode ?? "" },
        //                onShare: {
        //                    // e.g., ShareLink or custom ActivityView
        //                }
        //            )
        //        }
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
    
    HomeView(selectedTab: .constant(.home), repo: MockFamilyRepo())
        .environmentObject(AppSession())
        .environmentObject(GlobalLocationCoordinator.preview())
}

// MARK: - Previews

//#Preview("HomeView — Organizer") {
//    let session = AppSession()
//
//    let fam1 = FamilyModel.demo(id: "fam_demo_123", name: "Gamble Family", organizerId: "user-1")
//    let fam2 = FamilyModel.demo(
//        id: "fam_other_456", name: "Co‑Parent Team", organizerId: "user-3",
//        members: [
//            "user-3": MemberMeta(role: .organizer, joinedAt: Date().addingTimeInterval(-200_000)),
//            "user-1": MemberMeta(role: .member,    joinedAt: Date().addingTimeInterval(-150_000))
//        ]
//    )
//
//    let user = UserModel.demo(uid: "user-1", name: "Sam", email: "sam@example.com", currentFamilyId: fam1.id ?? "")
//
//    session.loadPreviewState(user: user, family: fam1, families: [fam1, fam2])
//
//    HomeView(selectedTab: .constant(.home), repo: MockFamilyRepo())
//        .environmentObject(session)
//}
//
//#Preview("HomeView — Member") {
//    let session = AppSession()
//
//    let fam1 = FamilyModel.demo(
//        id: "fam_demo_123", name: "Gamble Family", organizerId: "user-99",
//        members: [
//            "user-99": MemberMeta(role: .organizer, joinedAt: Date()),
//            "user-2":  MemberMeta(role: .member,    joinedAt: Date().addingTimeInterval(-80_000))
//        ]
//    )
//
//    let user = UserModel.demo(uid: "user-2", name: "Alex", email: "alex@example.com", currentFamilyId: fam1.id ?? "")
//
//    session.loadPreviewState(user: user, family: fam1, families: [fam1])
//
//    HomeView(selectedTab: .constant(.home), repo: MockFamilyRepo())
//        .environmentObject(session)
//}
