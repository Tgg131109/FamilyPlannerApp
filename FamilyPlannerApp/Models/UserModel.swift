//
//  UserModel.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/5/25.
//

import Foundation
import FirebaseFirestore

struct UserModel: Codable, Identifiable {
    @DocumentID var id: String? // uid set by Firestore
    var displayName: String?
    var email: String?
    var role: UserRole
    var familyId: String?
    var status: AccountStatus
    var providerIds: [String]
    var createdAt: Date
    var updatedAt: Date
    
    init(uid: String, email: String?, displayName: String?, role: UserRole) {
        self.id = uid
        self.email = email
        self.displayName = displayName
        self.role = role
        self.familyId = nil
        self.status = .active
        self.providerIds = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Tolerant decoding for existing docs
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.displayName = try c.decodeIfPresent(String.self, forKey: .displayName)
        self.email = try c.decodeIfPresent(String.self, forKey: .email)
        self.role = try c.decodeIfPresent(UserRole.self, forKey: .role) ?? .organizer
        self.familyId = try c.decodeIfPresent(String.self, forKey: .familyId)
        self.status = try c.decodeIfPresent(AccountStatus.self, forKey: .status) ?? .active
        self.providerIds = try c.decodeIfPresent([String].self, forKey: .providerIds) ?? []
        self.createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
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
