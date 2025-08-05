import SwiftUI

struct PostSignUpView: View {
    let role: UserRole
    @EnvironmentObject var appState: AppState
    
    @State private var familyName: String = ""
    @State private var inviteCode: String = ""
    @State private var successMessage: String?
    @State private var generatedCode: String?
    
    var body: some View {
        VStack(spacing: 20) {
            if role == .organizer {
                // Organizer creates the family
                TextField("Family Name", text: $familyName)
                    .textFieldStyle(.roundedBorder)
                
                Button("Create Family") {
                    Task {
                        do {
                            let userId = FirebaseAuthService.shared.currentUserId!
                            let code = try await FirestoreService.shared.createFamily(name: familyName, ownerId: userId)
                            generatedCode = code
                            successMessage = "Family created successfully!"
                        } catch {
                            successMessage = error.localizedDescription
                        }
                    }
                }
                .disabled(familyName.isEmpty)
                .buttonStyle(.borderedProminent)
                .font(.title)
                .bold()
                
                if let code = generatedCode {
                    VStack(spacing: 8) {
                        Text("Your invite code:")
                            .font(.subheadline)
                        
                        Text(code)
                            .font(.title)
                            .bold()
                            .padding(.bottom)
                        
                        ShareLink("Share Code", item: code)
                    }
                }
            } else {
                // Member joins the family
                TextField("Enter Invite Code", text: $inviteCode)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.allCharacters)
                
                Button("Join Family") {
                    Task {
                        do {
                            if let familyId = try await FirestoreService.shared.validateInviteCode(inviteCode) {
                                let userId = FirebaseAuthService.shared.currentUserId!
                                try await FirestoreService.shared.addUserToFamily(userId: userId, familyId: familyId)
                                successMessage = "You’ve successfully joined the family!"
                            } else {
                                successMessage = "Invalid invite code. Try again."
                            }
                        } catch {
                            successMessage = error.localizedDescription
                        }
                    }
                }
                .disabled(inviteCode.isEmpty)
                .buttonStyle(.borderedProminent)
                .font(.title)
                .bold()
            }
            
            if let message = successMessage {
                Text(message)
                    .foregroundColor(message.contains("success") ? .green : .red)
                    .padding(.top)
            }
            
            // Done button always available once success
            if successMessage?.contains("success") == true {
                Button("Go to Home") {
                    appState.isSignedIn = true
                }
                .padding(.top)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Family Setup")
    }
}

#Preview {
    NavigationStack {
        PostSignUpView(role: .organizer)
            .environmentObject(AppState())
    }
}
