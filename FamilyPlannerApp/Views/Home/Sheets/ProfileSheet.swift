//
//  ProfileSheet.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/13/25.
//

import SwiftUI

struct ProfileView: View {
    @State private var profileImage: Image? = Image(systemName: "person.circle.fill")
    @State private var displayName: String = "John Doe"
    @State private var email: String = "john@example.com"
    @State private var role: String = "Organizer"
    @State private var joinDate: Date = Date(timeIntervalSince1970: 1_675_000_000)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // MARK: - Profile Picture
                VStack {
                    profileImage?
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                        .padding(.bottom, 8)
                    
                    Text(displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(role)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                Divider()
                
                // MARK: - Profile Details
                VStack(spacing: 12) {
                    HStack {
                        Label("Joined", systemImage: "calendar")
                        Spacer()
                        Text(joinDate, style: .date)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        Label("Family", systemImage: "house")
                        Spacer()
                        Text("Gamble Household")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        Label("Members", systemImage: "person.3")
                        Spacer()
                        Text("5")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .padding(.horizontal)
                
                Divider()
                
                // MARK: - Actions
                VStack(spacing: 16) {
                    Button(action: {
                        // Edit Profile Action
                    }) {
                        Label("Edit Profile", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        // Manage Household Action
                    }) {
                        Label("Manage Household", systemImage: "house.and.flag")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    Button(role: .destructive, action: {
                        // Sign Out Action
                    }) {
                        Label("Sign Out", systemImage: "arrowshape.turn.up.left")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        ProfileView()
    }
}
