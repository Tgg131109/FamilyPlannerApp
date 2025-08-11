//
//  FamilyPlannerAppApp.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/4/25.
//

import SwiftUI
import Firebase

@main
struct FamilyPlannerApp: App {
    @StateObject private var session = AppSession()
    @StateObject private var locationCoordinator = GlobalLocationCoordinator()
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .environmentObject(locationCoordinator)
                .task { await session.start() }
        }
    }
}

//@main
//struct FamilyPlannerApp: App {
//    @StateObject private var session = AppManager()
//    @StateObject private var locationCoordinator = GlobalLocationCoordinator()
//    @StateObject private var router = AppFlowRouter()
//    
//    init() {
//        FirebaseApp.configure()
//    }
//    
//    var body: some Scene {
//        WindowGroup {
//            switch router.flow {
//            case .welcome:
//                // Own the NavigationStack here; not elsewhere
//                NavigationStack {
//                    WelcomeView()
//                        .environmentObject(router)
//                        .environmentObject(session)
//                        .environmentObject(locationCoordinator)
//                }
//                
//            case .familySetup(let role):
//                NavigationStack {
//                    PostSignUpView(role: role)
//                        .environmentObject(router)
//                }
//                
//            case .main:
//                MainTabView()
//                    .environmentObject(router)
//                    .environmentObject(session)
//                    .environmentObject(locationCoordinator)
//            }
//            //            NavigationStack(path: $router.path) {
//            //                Group {
////            if session.isLoading {
////                ProgressView("Loading…")
////            } else if session.user != nil, session.family != nil {
////                NavigationStack{
////                    MainTabView()
////                        .environmentObject(session)
////                        .environmentObject(locationCoordinator)
////                }
////            } else {
////                NavigationStack {
////                    WelcomeView()
////                        .environmentObject(session)
////                        .environmentObject(locationCoordinator)
////                }
////            }
//            //                }
//            //                // All destinations live on THIS stack
//            //                .navigationDestination(for: AuthRoute.self) { route in
//            //                    switch route {
//            //                    case .signIn: SignInView()
//            //                    case .signUp:
//            //                        SignUpView { role in
//            //                            router.path.append(.postSignUp(role))
//            //                        }
//            //                    case .postSignUp(let role):
//            //                        PostSignUpView(role: role)
//            //                    }
//            //                }
//            //            }
//            //            .environmentObject(session)
//            //            .environmentObject(locationCoordinator)
//            
//            //            if appState.isSignedIn {
//            //                MainTabView()
//            //                    .environmentObject(appState)
//            //                    .environmentObject(session)
//            //                    .environmentObject(locationCoordinator)
//            //            } else {
//            //                WelcomeView()
//            //                    .environmentObject(appState)
//            //                    .environmentObject(session)
//            //                    .environmentObject(locationCoordinator)
//            //            }
//        }
//    }
//}
//
//enum AppFlow: Equatable {
//    case welcome            // unauth screens (Welcome, Sign In/Up)
//    case familySetup(UserRole) // post‑signup screen
//    case main               // MainTabView
//}
//
//final class AppFlowRouter: ObservableObject {
//    @Published var flow: AppFlow = .welcome
//    
//    func goWelcome() { flow = .welcome }
//    func goFamilySetup(_ role: UserRole) { flow = .familySetup(role) }
//    func goMain() { flow = .main }
//}
