//
//  HomeView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/4/25.
//

import SwiftUI
import CoreLocation

// The main Home screen for the Family Planner app
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel() // MVVM pattern
    @Binding var selectedTab: MainTabView.Tab // Binding to control tab selection
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                
                // Personalized greeting
                Text("\(viewModel.greeting), \(viewModel.username)!")
                    .font(.title2)
                    .bold()
                
                RemindersCardView()
                
                TodayCardView() {
                    selectedTab = .calendar
                }
                // Scrollable stack of navigation cards
                ScrollView {
                    VStack(spacing: 12) {
                        if #available(iOS 16.0, *) {
                            WeatherCardWithLocationView()
                        } else {
                            WeatherCardWithLocationView()
                        }
                        // Each HomeCardView opens a specific module
                        //                        NavigationLink(destination: CalendarScreen()) {
                        //                            HomeCardView(title: "Calendar", systemImage: "calendar", color: .blue)
                        //                        }
                        
//                        HomeCardView(title: "Calendar", systemImage: "calendar", color: .blue) {
//                            selectedTab = .calendar
//                        }
                        
//                        HomeCardView(title: "Recipes & Meal Plan", systemImage: "fork.knife", color: .orange) {
//                            selectedTab = .recipes
//                        }
//                        
//                        HomeCardView(title: "Shopping List", systemImage: "cart.fill", color: .green) {
//                            selectedTab = .recipes // optional: route deeper inside recipes later
//                        }
//                        
//                        HomeCardView(title: "Family Chat", systemImage: "bubble.left.and.bubble.right.fill", color: .purple) {
//                            selectedTab = .chat
//                        }
//                        
//                        HomeCardView(title: "Location Map", systemImage: "map.fill", color: .teal) {
//                            selectedTab = .location
//                        }
                    }
                }
                
                Spacer() // Pushes content upward
            }
            .padding(.horizontal)
            .navigationTitle("Home")
            .toolbarVisibility(.hidden, for: .automatic)
//            .background(Color.orange.edgesIgnoringSafeArea(.all))
        }
    }
}

#Preview {
    HomeView(selectedTab: .constant(.home))
        .environmentObject(GlobalLocationCoordinator.preview())
}
