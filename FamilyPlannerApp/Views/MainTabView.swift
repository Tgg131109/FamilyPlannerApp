//
//  MainTabView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/4/25.
//

import SwiftUI

// MainTabView defines the primary TabBar layout of the app
struct MainTabView: View {
//    @StateObject private var appState = AppState()
    // State variable to control the currently selected tab
    @State private var selectedTab: Tab = .home

    // Custom enum to track and manage tab routes
    enum Tab: Hashable {
        case home, calendar, location, chat, recipes, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)

            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(Tab.calendar)

            LocationView()
                .tabItem { Label("Location", systemImage: "map") }
                .tag(Tab.location)

            ChatView()
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(Tab.chat)

            RecipesView()
                .tabItem { Label("Recipes", systemImage: "fork.knife") }
                .tag(Tab.recipes)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
    }
}


//struct HomeView: View { var body: some View { Text("Home").navigationTitle("Home") } }
struct CalendarView: View { var body: some View { Text("Calendar").navigationTitle("Calendar") } }
struct LocationView: View { var body: some View { Text("Location").navigationTitle("Location") } }
struct ChatView: View { var body: some View { Text("Chat").navigationTitle("Chat") } }
struct RecipesView: View { var body: some View { Text("Recipes").navigationTitle("Recipes") } }
struct SettingsView: View { var body: some View { Text("Settings").navigationTitle("Settings") } }

#Preview {
    MainTabView()
        .environmentObject(AppSession())
        .environmentObject(GlobalLocationCoordinator.preview())
}
