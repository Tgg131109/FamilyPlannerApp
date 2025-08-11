//
//  WelcomeView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/4/25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var showSignIn = false
    @State private var showSignUp = false
    //    @EnvironmentObject var appState: AppState
    //    @State private var path: [AuthRoute] = []
    //    @EnvironmentObject var router: AppFlowRouter
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Family Planner").font(.largeTitle).bold()
            Text("Welcome! Sign in or create an account.").foregroundStyle(.secondary)
            Spacer()
            Button("Sign In") { showSignIn = true }.buttonStyle(.borderedProminent)
            Button("Create Account") { showSignUp = true }.buttonStyle(.bordered)
            Spacer(minLength: 40)
        }
        .sheet(isPresented: $showSignIn) { SignInView() }
        .sheet(isPresented: $showSignUp) { SignUpView() }
        .padding()
    }
    
    //    var body: some View {
    //        NavigationStack {
    //            VStack(spacing: 32) {
    //                Text("👨‍👩‍👧‍👦 Family Planner")
    //                    .font(.largeTitle)
    //                    .bold()
    //
    //                Text("Plan meals, share calendars, keep your family connected.")
    //                    .multilineTextAlignment(.center)
    //                    .padding(.horizontal)
    //
    //                //                // Use value-based links instead of pushing concrete views
    //                //                NavigationLink("Sign In", value: AuthRoute.signIn)
    //                //                    .buttonStyle(.borderedProminent)
    //                //
    //                //                NavigationLink("Sign Up", value: AuthRoute.signUp)
    //                //                    .buttonStyle(.bordered)
    //
    //                NavigationLink("Sign In") {
    //                    SignInView()
    //                }
    //                .buttonStyle(.borderedProminent)
    //
    //                NavigationLink("Sign Up", ) {
    //                    SignUpView { role in
    //                        router.goFamilySetup(role)   // ← explicit handoff
    //                    }
    //                }
    //                .buttonStyle(.bordered)
    //
    //                Spacer()
    //            }
    //            .padding()
    //            //            // All destinations live on the SAME stack:
    //            //            .navigationDestination(for: AuthRoute.self) { route in
    //            //                switch route {
    //            //                case .signIn:
    //            //                    SignInView()
    //            //
    //            //                case .signUp:
    //            //                    // Pass a completion closure instead of using .navigationDestination in SignUpView
    //            //                    SignUpView { role in
    //            //                        // push to Family setup after successful account creation
    //            //                        path.append(.postSignUp(role))
    //            //                    }
    //            //
    //            //                case .postSignUp(let role):
    //            //                    PostSignUpView(role: role)
    //            //                }
    //            //            }
    //        }
    //    }
}

//final class Router: ObservableObject {
//    @Published var path: [AuthRoute] = []
//}

//enum AuthRoute: Hashable {
//    case signIn
//    case signUp
//    case postSignUp(UserRole)
//}

#Preview {
    WelcomeView()
}
