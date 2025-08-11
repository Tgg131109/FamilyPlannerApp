//
//  FirestoreService.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/5/25.
//

//import Foundation
//import FirebaseFirestore
//
//final class FirestoreService {
//    static let shared = FirestoreService()
//    private let db = Firestore.firestore()
//    private init() {}
//
//    // MARK: - Users
//
//    func createUserDocument(uid: String, fullName: String, email: String, role: UserRole) async throws {
//        let user = UserModel(
//            uid: uid,
//            fullName: fullName,
//            email: email,
//            role: role,
//            familyId: nil,
//            createdAt: Date(),
//            updatedAt: Date()
//        )
//        try db.collection("users").document(uid).setData(from: user)
//    }
//
//    func setUserFamily(uid: String, familyId: String) async throws {
//        try await db.collection("users").document(uid).setData([
//            "familyId": familyId,
//            "updatedAt": FieldValue.serverTimestamp()
//        ], merge: true)
//    }
//
//    // MARK: - Families
//
//    /// Creates a family AND attaches the current user (as organizer) atomically.
//    func createFamilyAndAttachOwner(familyName: String, ownerId: String)
//    async throws -> (familyId: String, inviteCode: String) {
//
//        // 1) Generate a unique invite code outside the tx
//        var chosenCode = ""
//        for _ in 0..<5 {
//            let code = generateInviteCode()
//            if try await !doesInviteCodeExist(code) { chosenCode = code; break }
//        }
//        guard !chosenCode.isEmpty else {
//            throw NSError(domain: "InviteCode", code: 1,
//                          userInfo: [NSLocalizedDescriptionKey: "Could not generate invite code. Try again."])
//        }
//
//        let families = db.collection("families")
//        let users = db.collection("users")
//
//        var createdFamilyId: String?
//
//        // 2) Transaction: NON-throwing closure with (txn, errorPointer)
//        _ = try await db.runTransaction({ (txn, errorPointer) -> Any? in
//            let familyRef = families.document()
//            createdFamilyId = familyRef.documentID
//
//            // Create family
//            txn.setData([
//                "name": familyName,
//                "ownerId": ownerId,
//                "inviteCode": chosenCode,
//                "createdAt": FieldValue.serverTimestamp()
//            ], forDocument: familyRef)
//
//            // Add owner as member
//            let memberRef = familyRef.collection("members").document(ownerId)
//            txn.setData([
//                "role": UserRole.organizer.rawValue,
//                "joinedAt": FieldValue.serverTimestamp()
//            ], forDocument: memberRef)
//
//            // Update user's familyId
//            let userRef = users.document(ownerId)
//            txn.updateData([
//                "familyId": familyRef.documentID,
//                "updatedAt": FieldValue.serverTimestamp()
//            ], forDocument: userRef)
//
//            return nil
//        })
//
//        guard let fid = createdFamilyId else {
//            throw NSError(domain: "Transaction", code: 2,
//                          userInfo: [NSLocalizedDescriptionKey: "Family ID not created."])
//        }
//        return (familyId: fid, inviteCode: chosenCode)
//    }
//
//
//    /// Joins a family using code AND attaches the user atomically.
//    func joinFamilyWithCode(inviteCode: String, uid: String, role: UserRole)
//    async throws -> String {
//
//        let code = inviteCode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
//        let q = try await db.collection("families")
//            .whereField("inviteCode", isEqualTo: code)
//            .limit(to: 1)
//            .getDocuments()
//
//        guard let familyDoc = q.documents.first else {
//            throw NSError(domain: "InviteCode", code: 404,
//                          userInfo: [NSLocalizedDescriptionKey: "Invalid invite code"])
//        }
//
//        let familyId = familyDoc.documentID
//        let familyRef = db.collection("families").document(familyId)
//        let memberRef = familyRef.collection("members").document(uid)
//        let userRef = db.collection("users").document(uid)
//
//        _ = try await db.runTransaction({ (txn, errorPointer) -> Any? in
//            // Add/overwrite membership
//            txn.setData([
//                "role": role.rawValue,
//                "joinedAt": FieldValue.serverTimestamp()
//            ], forDocument: memberRef)
//
//            // Update user's familyId
//            txn.updateData([
//                "familyId": familyId,
//                "updatedAt": FieldValue.serverTimestamp()
//            ], forDocument: userRef)
//
//            return nil
//        })
//
//        return familyId
//    }
//
//
//    // MARK: - Helpers
//
//    private func generateInviteCode(length: Int = 6) -> String {
//        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789") // avoid 0/O, 1/I
//        return String((0..<length).compactMap { _ in chars.randomElement() })
//    }
//
//    private func doesInviteCodeExist(_ code: String) async throws -> Bool {
//        let snap = try await db.collection("families").whereField("inviteCode", isEqualTo: code).limit(to: 1).getDocuments()
//        return !snap.documents.isEmpty
//    }
//}
//
//extension FirestoreService {
//    func fetchUser(uid: String) async throws -> UserModel? {
//        let doc = try await db.collection("users").document(uid).getDocument()
//        guard doc.exists, let data = doc.data() else { return nil }
//        return UserModel(
//            id: doc.documentID,
//            uid: data["uid"] as? String ?? doc.documentID,
//            fullName: data["fullName"] as? String ?? "",
//            email: data["email"] as? String ?? "",
//            role: UserRole(rawValue: (data["role"] as? String ?? "member")) ?? .member,
//            familyId: data["familyId"] as? String,
//            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
//            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
//        )
//    }
//
//    func fetchFamily(familyId: String) async throws -> FamilyModel? {
//        let doc = try await db.collection("families").document(familyId).getDocument()
//        guard doc.exists, let data = doc.data() else { return nil }
//        return FamilyModel(
//            id: doc.documentID,
//            name: data["name"] as? String ?? "",
//            ownerId: data["ownerId"] as? String ?? "",
//            inviteCode: data["inviteCode"] as? String ?? "",
//            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
//        )
//    }
//}
