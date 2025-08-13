//
//  ProfileSheet.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/13/25.
//

import SwiftUI
import PhotosUI
import FirebaseAuth

struct ProfileSheet: View {
    @EnvironmentObject var session: AppSession
    @StateObject private var vm = ProfileViewModel()
    
    @State private var isEditing = false
    @State private var localDisplayName: String = ""
    @State private var errorBanner: String?
    
    // NEW: image picking
    @State private var photosItem: PhotosPickerItem?
    @State private var pickedImageData: Data?
    @State private var previewImage: Image? // local preview before upload
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: Header (Avatar + name/email/role)
                VStack(spacing: 8) {
                    ZStack {
                        ToolbarAvatar(
                            urlString: session.userDoc?.photoURL,
                            displayName: session.userDoc?.displayName,
                            size: 120
                        )
                        // If we picked an image, preview it; else show remote AsyncImage or placeholder
                        //                        if let previewImage {
                        //                            previewImage
                        //                                .resizable().scaledToFill()
                        //                                .frame(width: 120, height: 120)
                        //                                .clipShape(Circle())
                        //                                .shadow(radius: 6)
                        //                        } else if let url = vm.photoURL {
                        //                            AsyncImage(url: url) { phase in
                        //                                switch phase {
                        //                                case .success(let image):
                        //                                    image.resizable().scaledToFill()
                        //                                case .failure(_):
                        //                                    Image(systemName: "person.circle.fill").resizable().scaledToFit().foregroundStyle(.secondary)
                        //                                case .empty:
                        //                                    ProgressView()
                        //                                @unknown default:
                        //                                    Image(systemName: "person.circle.fill").resizable().scaledToFit().foregroundStyle(.secondary)
                        //                                }
                        //                            }
                        //                            .frame(width: 120, height: 120)
                        //                            .clipShape(Circle())
                        //                            .shadow(radius: 6)
                        //                        } else {
                        //                            Image(systemName: "person.circle.fill")
                        //                                .resizable().scaledToFit()
                        //                                .frame(width: 120, height: 120)
                        //                                .foregroundStyle(.secondary)
                        //                                .shadow(radius: 6)
                        //                        }
                        
                        if isEditing {
                            PhotosPicker(selection: $photosItem, matching: .images) {
                                Circle().fill(.black.opacity(0.35))
                                    .overlay(Image(systemName: "camera.fill").font(.title2).foregroundStyle(.white))
                                    .frame(width: 120, height: 120)
                            }
                            .contentShape(Circle())
                        }
                    }
                    
                    if isEditing {
                        TextField("Display Name", text: $localDisplayName)
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .textInputAutocapitalization(.words)
                    } else {
                        Text(vm.displayName).font(.title2.weight(.semibold))
                    }
                    
                    Text(vm.email).font(.subheadline).foregroundStyle(.secondary)
                    Text(vm.roleText).font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.top)
                
                if let err = errorBanner {
                    Text(err).foregroundStyle(.red).font(.footnote).padding(.horizontal)
                }
                
                Divider()
                
                // MARK: details (unchanged)
                VStack(spacing: 12) {
                    row(label: "Family", systemImage: "house", value: vm.familyName)
                    row(label: "Members", systemImage: "person.3", value: "\(vm.memberCount)")
                    row(label: "Joined", systemImage: "calendar", value: vm.joinedDateText)
                }
                .padding(.horizontal)
                
                Divider()
                
                // MARK: households list + picker (unchanged except for AnyShapeStyle fix)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Your Households", systemImage: "list.bullet")
                        Spacer()
                        if vm.isSwitching { ProgressView() }
                    }
                    
                    if !vm.households.isEmpty {
                        Picker("Active Household", selection: $vm.activeFamilyId) {
                            ForEach(vm.households, id: \.id) { fam in
                                Text(fam.name).tag(Optional(fam.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: vm.activeFamilyId) { _, newId in
                            Task {
                                let err = await vm.switchFamily(to: newId)
                                if let err { errorBanner = err }
                            }
                        }
                        
                        VStack(spacing: 8) {
                            ForEach(vm.households, id: \.id) { fam in
                                let isActive = (fam.id == vm.activeFamilyId)
                                HStack(spacing: 12) {
                                    Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(isActive ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(fam.name).font(.body)
                                        Text(fam.role).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if !isActive {
                                        Button(role: .destructive) {
                                            Task {
                                                let err = await vm.leaveFamily(fam.id)
                                                if let err { errorBanner = err }
                                            }
                                        } label: { Image(systemName: "figure.walk.departure") }
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    Task {
                                        let err = await vm.switchFamily(to: fam.id)
                                        if let err { errorBanner = err }
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        }
                        .padding(12)
                        .background(.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Text("You aren’t a member of any households yet.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // MARK: Actions
                HStack(spacing: 12) {
                    if isEditing {
                        Button {
                            isEditing = false
                            localDisplayName = vm.displayName
                            pickedImageData = nil
                            previewImage = nil
                        } label: {
                            Label("Cancel", systemImage: "xmark")
                                .frame(maxWidth: .infinity).padding()
                                .background(.gray.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button {
                            Task {
                                let err = await vm.saveProfile(newName: localDisplayName, pickedImageData: pickedImageData)
                                if let err { errorBanner = err } else {
                                    isEditing = false
                                    pickedImageData = nil
                                    previewImage = nil
                                }
                            }
                        } label: {
                            if vm.isSaving { ProgressView().frame(maxWidth: .infinity).padding() }
                            else { Label("Save Changes", systemImage: "checkmark").frame(maxWidth: .infinity).padding() }
                        }
                        .disabled(vm.isSaving || localDisplayName.trimmingCharacters(in: .whitespaces).isEmpty)
                        .background(.blue.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Button {
                            isEditing = true
                            localDisplayName = vm.displayName
                        } label: {
                            Label("Edit Profile", systemImage: "pencil")
                                .frame(maxWidth: .infinity).padding()
                                .background(.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button(role: .destructive) {
                            session.signOut()                    // your signOut is sync, non-throwing
                            if let msg = session.errorMessage {  // surface any error
                                errorBanner = msg
                            }
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.forward")
                                .frame(maxWidth: .infinity).padding()
                                .background(.red.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 32)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            vm.bind(session: session)
            await vm.loadInitial()
        }
        .onChange(of: photosItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    pickedImageData = data
                    if let ui = UIImage(data: data) {
                        previewImage = Image(uiImage: ui)  // instant local preview
                    }
                }
            }
        }
    }
    
    private func row(label: String, systemImage: String, value: String) -> some View {
        HStack {
            Label(label, systemImage: systemImage)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}


#Preview {
    NavigationView {
        ProfileSheet()
            .environmentObject(AppSession())
    }
}
