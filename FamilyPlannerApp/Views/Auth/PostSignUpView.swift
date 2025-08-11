//
//  PostSignUpView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/4/25.
//

//import SwiftUI

//struct PostSignUpView: View {
//    let role: UserRole
////    @EnvironmentObject var appState: AppState
//    @EnvironmentObject var router: AppFlowRouter
//    
//    @State private var familyName: String = ""
//    @State private var inviteCode: String = ""
//    @State private var generatedCode: String?
//    @State private var message: String?
//    @State private var isBusy = false
//
//    var body: some View {
//        VStack(spacing: 16) {
//            Text("Family Setup").font(.title).bold()
//
//            if role == .organizer {
//                TextField("Family Name", text: $familyName).textFieldStyle(.roundedBorder)
//
//                Button {
//                    Task { await createFamily() }
//                } label: {
//                    if isBusy { ProgressView() } else { Text("Create Family") }
//                }
//                .buttonStyle(.borderedProminent)
//                .disabled(familyName.trimmingCharacters(in: .whitespaces).isEmpty || isBusy)
//
//                if let code = generatedCode {
//                    VStack(spacing: 8) {
//                        Text("Invite Code").font(.subheadline)
//                        Text(code).font(.title).bold()
//                        ShareLink("Share Code", item: "Join our family in the app with code: \(code)")
//                    }
//                    .padding(.top, 8)
//
//                    Button("Go to Home") { router.goMain() }
//                        .buttonStyle(.borderedProminent)
//                        .padding(.top, 8)
//                }
//            } else {
//                TextField("Enter Invite Code", text: $inviteCode)
//                    .textFieldStyle(.roundedBorder)
//                    .textInputAutocapitalization(.characters)
//
//                Button {
//                    Task { await joinFamily() }
//                } label: {
//                    if isBusy { ProgressView() } else { Text("Join Family") }
//                }
//                .buttonStyle(.borderedProminent)
//                .disabled(inviteCode.trimmingCharacters(in: .whitespaces).isEmpty || isBusy)
//            }
//
//            if let msg = message {
//                Text(msg)
//                    .font(.footnote)
//                    .foregroundColor(msg.lowercased().contains("success") ? .green : .red)
//                    .padding(.top, 4)
//            }
//
//            Spacer()
//        }
//        .padding()
//        .navigationTitle("Family Setup")
//    }
//
//    // MARK: - Actions
//
//    private func createFamily() async {
//        guard let uid = FirebaseAuthService.shared.currentUserId() else { return }
//        
//        isBusy = true; message = nil
//        
//        do {
//            let result = try await FirestoreService.shared.createFamilyAndAttachOwner(familyName: familyName, ownerId: uid)
//            generatedCode = result.inviteCode
//            message = "Success! Your family was created."
//        } catch {
//            message = error.localizedDescription
//        }
//        
//        isBusy = false
//    }
//
//    private func joinFamily() async {
//        guard let uid = FirebaseAuthService.shared.currentUserId() else { return }
//        isBusy = true; message = nil
//        do {
//            _ = try await FirestoreService.shared.joinFamilyWithCode(inviteCode: inviteCode, uid: uid, role: .member)
//            message = "Success! You’ve joined the family."
//            // Short delay so the user sees the success, then proceed
//            try? await Task.sleep(nanoseconds: 600_000_000)
////            appState.isSignedIn = true
//            router.goMain()
//        } catch {
//            message = error.localizedDescription
//        }
//        isBusy = false
//    }
//}
//
//#Preview {
//    NavigationStack { PostSignUpView(role: .organizer) }
//        .environmentObject(AppState())
//}
