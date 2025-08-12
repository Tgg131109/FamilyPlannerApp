//
//  MainTabView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/4/25.
//

import SwiftUI

// MainTabView defines the primary TabBar layout of the app
struct MainTabView: View {
    @State private var selectedTab: AppTab = .home    

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppTab.home)

            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(AppTab.calendar)

            LocationView()
                .tabItem { Label("Location", systemImage: "map") }
                .tag(AppTab.location)

            ChatView()
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(AppTab.chat)

            RecipesView()
                .tabItem { Label("Recipes", systemImage: "fork.knife") }
                .tag(AppTab.recipes)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
    }
}

// Custom enum to track and manage tab routes
enum AppTab: Hashable {
    case home, calendar, location, chat, recipes, settings
}

//struct HomeView: View { var body: some View { Text("Home").navigationTitle("Home") } }
struct CalendarView: View { var body: some View { Text("Calendar").navigationTitle("Calendar") } }
//struct LocationView: View { var body: some View { Text("Location").navigationTitle("Location") } }
struct ChatView: View { var body: some View { Text("Chat").navigationTitle("Chat") } }
struct RecipesView: View { var body: some View { Text("Recipes").navigationTitle("Recipes") } }
struct SettingsView: View { var body: some View { Text("Settings").navigationTitle("Settings") } }

#Preview {
    MainTabView()
        .environmentObject(AppSession())
        .environmentObject(GlobalLocationCoordinator.preview())
}
