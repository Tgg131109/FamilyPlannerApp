//
//  UserRepositorying.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/10/25.
//

import Foundation

@MainActor
protocol UserRepositorying {
    func get(uid: String) async throws -> UserModel?
    func upsert(_ user: UserModel) async throws
}
