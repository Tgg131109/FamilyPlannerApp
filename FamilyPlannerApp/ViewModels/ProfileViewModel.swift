//
//  ProfileViewModel.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/13/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@MainActor
final class ProfileViewModel: ObservableObject {
    // MARK: - Output (UI)
    @Published var displayName: String = "—"
    @Published var email: String = "—"
    @Published var familyName: String = "—"
    @Published var roleText: String = "—"
    @Published var memberCount: Int = 0
    @Published var joinedDateText: String = "—"
    @Published var photoURL: URL?
    
    @Published var isSaving = false
    @Published var isSwitching = false
    
    struct HouseholdRow: Identifiable, Equatable {
        let id: String
        let name: String
        let role: String
    }
    
    @Published var households: [HouseholdRow] = []
    @Published var activeFamilyId: String?
    
    // MARK: - Bridge
    private weak var session: AppSession?
    
    // Convenience
    private var uid: String? { session?.userDoc?.id ?? Auth.auth().currentUser?.uid }
    
    // MARK: - Bind + Load
    func bind(session: AppSession) {
        self.session = session
    }
    
    func loadInitial() async {
        guard let session else { return }
        
        // User
        displayName = session.userDoc?.displayName ?? "—"
        email       = session.userDoc?.email ?? "—"
        activeFamilyId = session.familyDoc?.id ?? session.userDoc?.currentFamilyId
        
        if let s = session.userDoc?.photoURL, let u = URL(string: s) {
            photoURL = u
        } else {
            photoURL = nil
            
            // Check if photo exists and field is missing from profile
            await backfillPhotoURLIfMissing()
        }
        
        // Family
        if let fam = session.familyDoc {
            familyName  = fam.name
            memberCount = fam.members.count
            if
                let u = session.userDoc,
                let meta = fam.members[u.id ?? ""]
            {
                roleText = meta.role.rawValue.capitalized
                
                let d = meta.joinedAt
                
                joinedDateText = DateFormatter.localizedString(from: d, dateStyle: .medium, timeStyle: .none)
            } else {
                roleText = "—"
                joinedDateText = "—"
            }
        } else {
            familyName = "—"
            memberCount = 0
            roleText = "—"
            joinedDateText = "—"
        }
        
        // Households list (from session.userFamilies)
        var rows: [HouseholdRow] = []
        for fam in session.userFamilies {
            let fid = fam.id ?? ""
            let role = session.userDoc?.memberships[fid]?.role.rawValue.capitalized ?? "Member"
            rows.append(.init(id: fid, name: fam.name, role: role))
        }
        
        // Ensure active family appears even if not in userFamilies (defensive)
        if let active = activeFamilyId, rows.contains(where: { $0.id == active }) == false, let f = session.familyDoc {
            rows.append(.init(id: active, name: f.name, role: "Member"))
        }
        
        // Sort: active first, then name
        households = rows
            .uniqued(by: \.id)
            .sorted { a, b in
                if a.id == activeFamilyId { return true }
                if b.id == activeFamilyId { return false }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
    }
    
    func backfillPhotoURLIfMissing() async {
        guard let uid = uid, photoURL == nil else { return }
        let ref = Storage.storage().reference().child("profilePhotos/\(uid)/avatar.jpg")
        
        do {
            let url = try await ref.downloadURL()
            
            try await Collections.users.document(uid).updateData([
                "photoURL": url.absoluteString,
                "updatedAt": Timestamp(date: Date())
            ])
            
            await session?.performRefresh()
            
            if let s = session?.userDoc?.photoURL, let u = URL(string: s) {
                self.photoURL = u
            }
        } catch { /* ignore if file doesn’t exist */ }
    }
    
    // MARK: - Save user profile
    
    func saveProfile(newName: String, pickedImageData: Data?) async -> String? {
        guard let uid else { return "Not signed in." }
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "Display name can’t be empty." }
        
        isSaving = true
        defer { isSaving = false }
        
        var patch: [String: Any] = [
            "displayName": trimmed,
            "updatedAt": Timestamp(date: Date())
        ]
        
        // If a new image was picked, upload to Storage and get a download URL
        if let data = pickedImageData,
           let uploadData = await downscaleAndCompressAvatar(data: data, maxPixel: 512, targetKB: 200) {
            
            let ref = Storage.storage().reference().child("profilePhotos/\(uid)/avatar.jpg")
            let meta = StorageMetadata()
            
            meta.contentType = "image/jpeg"
            
            do {
                _ = try await ref.putDataAsync(uploadData, metadata: meta)
                
                let url = try await ref.downloadURL()
                
                patch["photoURL"] = url.absoluteString
                
                self.photoURL = url
            } catch {
                return (error as NSError).localizedDescription
            }
        }
        do {
            try await Collections.users.document(uid).updateData([
                "displayName": trimmed,
                "updatedAt": Timestamp(date: Date())
            ])
            
            await session?.performRefresh()
            
            displayName = session?.userDoc?.displayName ?? trimmed
            
            return nil
        } catch {
            return (error as NSError).localizedDescription
        }
    }
    
    // MARK: - Image processing (downscale + compress to keep uploads tiny)
    private func downscaleAndCompressAvatar(data: Data, maxPixel: CGFloat, targetKB: Int) async -> Data? {
        guard let src = UIImage(data: data) else { return nil }
        let w = src.size.width, h = src.size.height
        let scale = min(maxPixel / max(w, h), 1)
        let tgt = CGSize(width: floor(w * scale), height: floor(h * scale))
        
        let format = UIGraphicsImageRendererFormat()
        
        format.scale = 1
        
        let img = UIGraphicsImageRenderer(size: tgt, format: format).image { _ in
            src.draw(in: CGRect(origin: .zero, size: tgt))
        }
        
        var q: CGFloat = 0.82
        let targetBytes = targetKB * 1024
        var jpeg = img.jpegData(compressionQuality: q)
        var tries = 0
        
        while let d = jpeg, d.count > targetBytes, tries < 5 {
            q *= 0.82
            jpeg = img.jpegData(compressionQuality: q)
            tries += 1
        }
        
        return jpeg ?? img.pngData()
    }
    
    // MARK: - Switch family (mirrors HomeViewModel.switchFamily)
    func switchFamily(to familyId: String?) async -> String? {
        guard let familyId, let uid, let session else { return "Not signed in." }
        isSwitching = true
        defer { isSwitching = false }
        
        do {
            try await Collections.users.document(uid).updateData([
                "currentFamilyId": familyId,
                "updatedAt": Timestamp(date: Date())
            ])
            await session.performRefresh()
            // Recompute UI after refresh
            await loadInitial()
            return nil
        } catch {
            return (error as NSError).localizedDescription
        }
    }
    
    // MARK: - Leave family (non-active)
    func leaveFamily(_ familyId: String) async -> String? {
        guard let uid else { return "Not signed in." }
        if familyId == activeFamilyId {
            return "You can’t leave the active household. Switch to another first."
        }
        
        let db = Firestore.firestore()
        let userRef = Collections.users.document(uid)
        let famRef  = Collections.families.document(familyId)
        
        do {
            _ = try await db.runTransaction { txn, errPtr in
                do {
                    // Remove from family.members
                    let famSnap = try txn.getDocument(famRef)
                    let famData = famSnap.data() ?? [:]
                    var members = famData["members"] as? [String: Any] ?? [:]
                    members.removeValue(forKey: uid)
                    txn.updateData(["members": members, "updatedAt": Timestamp(date: Date())], forDocument: famRef)
                    
                    // Remove from user.memberships or user.families maps
                    let userSnap = try txn.getDocument(userRef)
                    let u = userSnap.data() ?? [:]
                    var memberships = (u["memberships"] as? [String: Any]) ?? [:]
                    var families    = (u["families"]    as? [String: Any]) ?? [:]
                    
                    if memberships[familyId] != nil {
                        memberships.removeValue(forKey: familyId)
                        txn.updateData(["memberships": memberships, "updatedAt": Timestamp(date: Date())], forDocument: userRef)
                    } else if families[familyId] != nil {
                        families.removeValue(forKey: familyId)
                        txn.updateData(["families": families, "updatedAt": Timestamp(date: Date())], forDocument: userRef)
                    }
                    return nil
                } catch {
                    errPtr?.pointee = error as NSError
                    return nil
                }
            }
            
            await session?.performRefresh()
            await loadInitial()
            
            return nil
        } catch {
            return (error as NSError).localizedDescription
        }
    }
}

// MARK: - Small helpers
private extension Array {
    func uniqued<ID: Hashable>(by keyPath: KeyPath<Element, ID>) -> [Element] {
        var seen = Set<ID>()
        var out: [Element] = []
        out.reserveCapacity(count)
        for e in self {
            let k = e[keyPath: keyPath]
            if seen.insert(k).inserted { out.append(e) }
        }
        return out
    }
}
