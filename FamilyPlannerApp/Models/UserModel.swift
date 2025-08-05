//
//  UserModel.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/5/25.
//

import Foundation

struct UserModel: Codable {
    var uid: String
    var name: String
    var email: String
    var role: String // "organizer" or "member"
    var familyId: String?
}
