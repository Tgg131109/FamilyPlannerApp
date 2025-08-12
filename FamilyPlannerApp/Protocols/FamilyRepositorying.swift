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
    
    func addMemberTransaction(
        familyId fid: String,
        memberUID: String,
        addedBy organizerUID: String,
        role: UserRole
    ) async throws
    
    func removeMemberTransaction(
        familyId fid: String,
        memberUID: String,
        actingOrganizerUID: String
    ) async throws
    
    func leaveFamilyTransaction(
        familyId fid: String,
        uid: String
    ) async throws
    
    // Optional join request flow (only add if you use it)
    func requestToJoinTransaction(familyId fid: String, uid: String, email: String) async throws
    func approveJoinRequestTransaction(familyId fid: String, uid: String, approvedBy organizerUID: String) async throws
    func rejectJoinRequestTransaction(familyId fid: String, uid: String) async throws
    
    // Optional: rotate join code
    func rotateJoinCodeTransaction(fid: String) async throws
}
