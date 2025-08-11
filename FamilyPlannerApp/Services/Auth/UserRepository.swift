//
//  UserRepository.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/10/25.
//

import Foundation
import FirebaseFirestore

@MainActor
final class UserRepository: UserRepositorying {
    func get(uid: String) async throws -> UserModel? {
        let snap = try await Collections.users.document(uid).getDocument()
        
        guard snap.exists else { return nil }
        
        var user = try snap.data(as: UserModel.self)
        // Custom Decodable can leave @DocumentID nil — restore it from the snapshot
        if user.id == nil { user.id = snap.documentID }
        
        return user
    }
    
    func upsert(_ user: UserModel) async throws {
        guard let uid = user.id else { throw NSError(domain: "AppUserMissingUID", code: -1) }
        var u = user; u.updatedAt = Date()
        try Collections.users.document(uid).setData(from: u, merge: true)
    }
}
