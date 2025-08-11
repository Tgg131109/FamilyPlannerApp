//
//  FamilyRepository.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/10/25.
//

import Foundation
import FirebaseFirestore

@MainActor
final class FamilyRepository: FamilyRepositorying {
    func familyByJoinCode(_ code: String) async throws -> (id: String, family: FamilyModel)? {
        let q = Collections.families.whereField("joinCode", isEqualTo: code.uppercased()).limit(to: 1)
        let snap = try await q.getDocuments()
        guard let doc = snap.documents.first else { return nil }
        let fam = try doc.data(as: FamilyModel.self)
        return (doc.documentID, fam)
    }
    
    // CREATE FAMILY: mirror membership on user + set currentFamilyId
    func createFamilyTransaction(name: String, organizerUID: String) async throws -> String {
        let db = Firestore.firestore()
        let fid = Collections.families.document().documentID
        let joinCode = Self.generateJoinCode()
        let now = Date()
        
        let members: [String: MemberMeta] = [organizerUID: MemberMeta(role: .organizer, joinedAt: now)]
        let family = FamilyModel(id: fid, name: name, organizerId: organizerUID, joinCode: joinCode, members: members, createdAt: now, updatedAt: now)
        let fRef = Collections.families.document(fid)
        let uRef = Collections.users.document(organizerUID)
        let familyData = try Firestore.Encoder().encode(family)
        
        _ = try await db.runTransaction { txn, errorPointer -> Any? in
            txn.setData(familyData, forDocument: fRef)
            txn.updateData([
                "memberships.\(fid).role": "organizer",
                "memberships.\(fid).joinedAt": Timestamp(date: now),
                "currentFamilyId": fid,
                "updatedAt": Timestamp(date: now)
            ], forDocument: uRef)
            return nil
        }
        return fid
    }
    
    // JOIN FAMILY: update family.members + user.memberships (leave currentFamilyId to session to set if nil)
    func joinFamilyByCodeTransaction(code: String, uid: String) async throws -> String {
        let db = Firestore.firestore()
        guard let (fid, _) = try await familyByJoinCode(code.uppercased()) else {
            throw NSError(domain: "JoinCodeNotFound", code: 404, userInfo: [NSLocalizedDescriptionKey: "No family found for code \(code)"])
        }
        let now = Date()
        let fRef = Collections.families.document(fid)
        let uRef = Collections.users.document(uid)
        
        _ = try await db.runTransaction { txn, errorPointer -> Any? in
            do {
                _ = try txn.getDocument(fRef)
                txn.updateData([
                    "members.\(uid).role": "member",
                    "members.\(uid).joinedAt": Timestamp(date: now),
                    "updatedAt": Timestamp(date: now)
                ], forDocument: fRef)
                txn.updateData([
                    "memberships.\(fid).role": "member",
                    "memberships.\(fid).joinedAt": Timestamp(date: now),
                    "updatedAt": Timestamp(date: now)
                ], forDocument: uRef)
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        return fid
    }
    
    
    static func generateJoinCode(length: Int = 6) -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<length).compactMap { _ in alphabet.randomElement() })
    }
}
