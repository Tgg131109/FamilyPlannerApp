//
//  FamilyRepositorying.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/10/25.
//

import Foundation

@MainActor
protocol FamilyRepositorying {
    func familyByJoinCode(_ code: String) async throws -> (id: String, family: FamilyModel)?
    func createFamilyTransaction(name: String, organizerUID: String) async throws -> String
    func joinFamilyByCodeTransaction(code: String, uid: String) async throws -> String
}
