//
//  HomeView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/4/25.
//

import SwiftUI
import CoreLocation

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var session: AppSession
    //    @Binding var selectedTab: MainTabView.Tab
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                //                Text("\(viewModel.greeting), \($viewModel.username)!")
                //                    .font(.title2)
                //                    .bold()
                
                HeaderCardView(
                    greeting: viewModel.greeting,
                    displayName: viewModel.displayName,
                    familyName: viewModel.familyName
                )
                
                ScrollView {
                    VStack(spacing : 16) {
                        RemindersCardView()
                        
                        TodayCardView() {
                            //                    selectedTab = .calendar
                        }
                        
                        if #available(iOS 16.0, *) {
                            WeatherCardWithLocationView()
                        } else {
                            WeatherCardWithLocationView()
                        }
                        
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
            .navigationTitle("Home")            
            .toolbarVisibility(.hidden, for: .automatic)
        }
        .onAppear {
            viewModel.onAppear(session: session)
        }
        // Keep the header in sync with AppSession changes
        .onReceive(session.$userDoc) { _ in
            viewModel.refreshHeader(session: session)
        }
        .onReceive(session.$familyDoc) { _ in
            viewModel.refreshHeader(session: session)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppSession())
        .environmentObject(GlobalLocationCoordinator.preview())
}



//// The main Home screen for the Family Planner app
//struct HomeView: View {
//    @StateObject private var viewModel = HomeViewModel() // MVVM pattern
//    @Binding var selectedTab: MainTabView.Tab // Binding to control tab selection
//    @EnvironmentObject var session: AppManager
//
//    var body: some View {
//        NavigationStack {
//            VStack(alignment: .leading, spacing: 16) {
//                ScrollView {
//                    HomeHeaderView()
//                }
//                .scrollContentBackground(.hidden)
//                .refreshable {
//                    await session.loadSession(for: FirebaseAuthService.shared.currentUserId())
//                }
//
//                // Personalized greeting
//                Text("\(viewModel.greeting), \(viewModel.username)!")
//                    .font(.title2)
//                    .bold()
//
//                RemindersCardView()
//
//                TodayCardView() {
//                    selectedTab = .calendar
//                }
//                // Scrollable stack of navigation cards
//                ScrollView {
//                    VStack(spacing: 12) {
//                        if #available(iOS 16.0, *) {
//                            WeatherCardWithLocationView()
//                        } else {
//                            WeatherCardWithLocationView()
//                        }
//                        // Each HomeCardView opens a specific module
//                        //                        NavigationLink(destination: CalendarScreen()) {
//                        //                            HomeCardView(title: "Calendar", systemImage: "calendar", color: .blue)
//                        //                        }
//
//                        //                        HomeCardView(title: "Calendar", systemImage: "calendar", color: .blue) {
//                        //                            selectedTab = .calendar
//                        //                        }
//
//                        //                        HomeCardView(title: "Recipes & Meal Plan", systemImage: "fork.knife", color: .orange) {
//                        //                            selectedTab = .recipes
//                        //                        }
//                        //
//                        //                        HomeCardView(title: "Shopping List", systemImage: "cart.fill", color: .green) {
//                        //                            selectedTab = .recipes // optional: route deeper inside recipes later
//                        //                        }
//                        //
//                        //                        HomeCardView(title: "Family Chat", systemImage: "bubble.left.and.bubble.right.fill", color: .purple) {
//                        //                            selectedTab = .chat
//                        //                        }
//                        //
//                        //                        HomeCardView(title: "Location Map", systemImage: "map.fill", color: .teal) {
//                        //                            selectedTab = .location
//                        //                        }
//                    }
//                }
//
//                Spacer() // Pushes content upward
//            }
//            .padding(.horizontal)
//            .navigationTitle("Home")
//            .toolbarVisibility(.hidden, for: .automatic)
//            //            .background(Color.orange.edgesIgnoringSafeArea(.all))
//        }
//    }
//}
//
//#Preview {
//    // Build a quick preview session
//    let session = AppManager()
//    session.user = UserModel(
//        id: "u1", uid: "u1", fullName: "Taylor Morgan",
//        email: "taylor@example.com", role: .member,
//        familyId: "f1", createdAt: .now, updatedAt: .now
//    )
//    session.family = FamilyModel(id: "f1", name: "Morgan Fam", ownerId: "u2", inviteCode: "DEF456", createdAt: .now)
//    session.isLoading = false
//
//    return NavigationStack {
//        HomeView(selectedTab: .constant(.home))
//            .environmentObject(GlobalLocationCoordinator.preview())
//            .environmentObject(session)
//    }
//}
