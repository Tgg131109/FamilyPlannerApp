//
//  FamilyModel.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/5/25.
//

import Foundation
import FirebaseFirestore

struct FamilyModel: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var organizerId: String
    var joinCode: String
    var members: [String: MemberMeta]
    var createdAt: Date
    var updatedAt: Date
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.organizerId = try c.decodeIfPresent(String.self, forKey: .organizerId) ?? ""
        self.joinCode = try c.decodeIfPresent(String.self, forKey: .joinCode) ?? ""
        self.members = try c.decodeIfPresent([String: MemberMeta].self, forKey: .members) ?? [:]
        self.createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
    
    init(id: String?, name: String, organizerId: String, joinCode: String, members: [String: MemberMeta], createdAt: Date?, updatedAt: Date?) {
        self.id = id
        self.name = name
        self.organizerId = organizerId
        self.joinCode = joinCode
        self.members = members
        self.createdAt = createdAt ?? Date()
        self.updatedAt = updatedAt ?? Date()
    }
}

extension FamilyModel {
    static var demoFamily: FamilyModel {
        FamilyModel(
            id: "fam_demo_123",
            name: "Gamble Family",
            organizerId: "user-1",
            joinCode: "ABC123",
            members: [
                "user-1": MemberMeta(role: .organizer, joinedAt: Date()),
                "user-2": MemberMeta(role: .member,    joinedAt: Date().addingTimeInterval(-86_400)),
                "user-3": MemberMeta(role: .member,    joinedAt: Date().addingTimeInterval(-172_800))
            ],
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    static func demo(id: String, name: String, organizerId: String = "User-1", members: [String: MemberMeta]? = nil) -> FamilyModel {
        return FamilyModel.demoFamily
    }
}
