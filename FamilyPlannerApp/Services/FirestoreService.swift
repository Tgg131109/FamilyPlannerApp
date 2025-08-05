//
//  FirestoreService.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/5/25.
//

import Foundation
import FirebaseFirestore
//import FirebaseFirestoreSwift

final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Create Family

    func createFamily(name: String, ownerId: String) async throws -> String {
        let inviteCode = generateInviteCode()
        let family = FamilyModel(name: name, ownerId: ownerId, inviteCode: inviteCode)

        let ref = db.collection("families").document()
        try ref.setData(from: family)

        return inviteCode
    }

    // MARK: - Validate Invite Code

    func validateInviteCode(_ code: String) async throws -> String? {
        let snapshot = try await db.collection("families")
            .whereField("inviteCode", isEqualTo: code.uppercased())
            .getDocuments()

        guard let doc = snapshot.documents.first else { return nil }
        return doc.documentID // return the family ID
    }

    // MARK: - Link user to family

    func addUserToFamily(userId: String, familyId: String) async throws {
        try await db.collection("users").document(userId).setData([
            "familyId": familyId
        ], merge: true)
    }

    private func generateInviteCode(length: Int = 6) -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<length).compactMap { _ in characters.randomElement() })
    }
}
