//
//  UserModel.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/5/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

struct UserModel: Codable, Identifiable {
    @DocumentID var id: String?
    var displayName: String?
    var email: String?
    
    // LEGACY single-household field (kept for migration only)
    var familyId: String?
    
    var role: UserRole
    var memberships: [String: MemberMeta]
    var currentFamilyId: String?
    
    var status: AccountStatus
    var providerIds: [String]
    var createdAt: Date
    var updatedAt: Date
    
    var photoURL: String?
    
    init(uid: String, email: String?, displayName: String?, role: UserRole) {
        self.id = uid
        self.email = email
        self.displayName = displayName
        self.familyId = nil
        self.role = role
        self.memberships = [:]
        self.currentFamilyId = nil
        self.status = .active
        self.providerIds = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.photoURL = Auth.auth().currentUser?.photoURL?.absoluteString // optional convenience
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.displayName = try c.decodeIfPresent(String.self, forKey: .displayName)
        self.email = try c.decodeIfPresent(String.self, forKey: .email)
        self.familyId = try c.decodeIfPresent(String.self, forKey: .familyId) // legacy
        self.role = try c.decodeIfPresent(UserRole.self, forKey: .role) ?? .organizer
        self.memberships = try c.decodeIfPresent([String: MemberMeta].self, forKey: .memberships) ?? [:]
        self.currentFamilyId = try c.decodeIfPresent(String.self, forKey: .currentFamilyId)
        self.status = try c.decodeIfPresent(AccountStatus.self, forKey: .status) ?? .active
        self.providerIds = try c.decodeIfPresent([String].self, forKey: .providerIds) ?? []
        self.createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        self.photoURL = try c.decodeIfPresent(String.self, forKey: .photoURL) // may be nil / absent
    }
}

enum UserRole: String, Codable, CaseIterable, Identifiable {
    case organizer
    case member
    
    var id: String { rawValue }
}

enum AccountStatus: String, Codable {
    case active
    case pending
    case disabled
}

enum AppRoute: Equatable {
    case splash
    case signedOut
    case signedInNoProfile
    case needsFamilySetup(role: UserRole)
    case pendingMembership, active
}
