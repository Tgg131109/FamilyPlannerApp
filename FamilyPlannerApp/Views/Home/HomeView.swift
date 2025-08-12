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
                        
                        //                        if #available(iOS 16.0, *) {
                        //                            WeatherCardWithLocationView()
                        //                        } else {
                        //                            WeatherCardWithLocationView()
                        //                        }
                        
                        //                        Spacer()
                        
                        
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
