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

extension FamilyRepository {
    
    /// Organizer adds a member by uid (e.g., after the user entered joinCode, or you looked them up)
    func addMemberTransaction(familyId fid: String, memberUID: String, addedBy organizerUID: String, role: UserRole = .member) async throws {
        let db = Firestore.firestore()
        let fRef = Collections.families.document(fid)
        let uRef = Collections.users.document(memberUID)
        let now = Date()
        
        _ = try await db.runTransaction({ txn, errorPointer -> Any? in
            // Ensure family exists
            do {
                _ = try txn.getDocument(fRef)
            } catch let err as NSError {
                errorPointer?.pointee = err
                return nil
            }
            
            // Update family members map
            txn.updateData([
                "members.\(memberUID).role": role.rawValue,
                "members.\(memberUID).joinedAt": Timestamp(date: now),
                "updatedAt": Timestamp(date: now)
            ], forDocument: fRef)
            
            // Mirror to user.memberships
            txn.updateData([
                "memberships.\(fid).role": role.rawValue,
                "memberships.\(fid).joinedAt": Timestamp(date: now),
                "updatedAt": Timestamp(date: now)
            ], forDocument: uRef)
            
            return nil
        })
    }
    
    /// Member leaves household (self‑service)
    func leaveFamilyTransaction(familyId fid: String, uid: String) async throws {
        let db = Firestore.firestore()
        let fRef = Collections.families.document(fid)
        let uRef = Collections.users.document(uid)
        let now = Date()
        
        _ = try await db.runTransaction({ txn, errorPointer -> Any? in
            // Load family, check organizer constraint
            do {
                let snap = try txn.getDocument(fRef)
                if let data = snap.data(),
                   let organizerId = data["organizerId"] as? String,
                   organizerId == uid {
                    let err = NSError(domain: "CannotLeaveAsSoleOrganizer", code: 400,
                                      userInfo: [NSLocalizedDescriptionKey: "Transfer organizer before leaving."])
                    errorPointer?.pointee = err
                    return nil
                }
            } catch let err as NSError {
                errorPointer?.pointee = err
                return nil
            }
            
            // Remove from family.members and user.memberships
            txn.updateData([
                "members.\(uid)": FieldValue.delete(),
                "updatedAt": Timestamp(date: now)
            ], forDocument: fRef)
            
            txn.updateData([
                "memberships.\(fid)": FieldValue.delete(),
                "updatedAt": Timestamp(date: now)
            ], forDocument: uRef)
            
            return nil
        })
    }
    
    /// Organizer removes another member
    func removeMemberTransaction(familyId fid: String, memberUID: String, actingOrganizerUID: String) async throws {
        let db = Firestore.firestore()
        let fRef = Collections.families.document(fid)
        let uRef = Collections.users.document(memberUID)
        let now = Date()
        
        _ = try await db.runTransaction({ txn, errorPointer -> Any? in
            // Load family, block removing organizer
            do {
                let snap = try txn.getDocument(fRef)
                if let data = snap.data(),
                   let organizerId = data["organizerId"] as? String,
                   organizerId == memberUID {
                    let err = NSError(domain: "CannotRemoveOrganizer", code: 403,
                                      userInfo: [NSLocalizedDescriptionKey: "Transfer organizer first."])
                    errorPointer?.pointee = err
                    return nil
                }
            } catch let err as NSError {
                errorPointer?.pointee = err
                return nil
            }
            
            txn.updateData([
                "members.\(memberUID)": FieldValue.delete(),
                "updatedAt": Timestamp(date: now)
            ], forDocument: fRef)
            
            txn.updateData([
                "memberships.\(fid)": FieldValue.delete(),
                "updatedAt": Timestamp(date: now)
            ], forDocument: uRef)
            
            return nil
        })
    }
    
    /// Member joins with the join code (you already have `joinFamilyByCodeTransaction` — keep using it)
    /// Below are optional helpers if you add request/approve flow:
    
    func requestToJoinTransaction(familyId fid: String, uid: String, email: String) async throws {
        let db = Firestore.firestore()
        let fRef = Collections.families.document(fid)
        let now = Date()
        
        _ = try await db.runTransaction({ txn, errorPointer -> Any? in
            do { _ = try txn.getDocument(fRef) }
            catch let err as NSError { errorPointer?.pointee = err; return nil }
            txn.updateData([
                "pendingRequests.\(uid).email": email.lowercased(),
                "pendingRequests.\(uid).requestedAt": Timestamp(date: now),
                "updatedAt": Timestamp(date: now)
            ], forDocument: fRef)
            return nil
        })
    }
    
    func approveJoinRequestTransaction(familyId fid: String, uid: String, approvedBy organizerUID: String) async throws {
        let db = Firestore.firestore()
        let fRef = Collections.families.document(fid)
        let uRef = Collections.users.document(uid)
        let now = Date()
        
        _ = try await db.runTransaction({ txn, errorPointer -> Any? in
            do { _ = try txn.getDocument(fRef) }
            catch let err as NSError { errorPointer?.pointee = err; return nil }
            // Promote pending -> member
            txn.updateData([
                "members.\(uid).role": UserRole.member.rawValue,
                "members.\(uid).joinedAt": Timestamp(date: now),
                "pendingRequests.\(uid)": FieldValue.delete(),
                "updatedAt": Timestamp(date: now)
            ], forDocument: fRef)
            txn.updateData([
                "memberships.\(fid).role": UserRole.member.rawValue,
                "memberships.\(fid).joinedAt": Timestamp(date: now),
                "updatedAt": Timestamp(date: now)
            ], forDocument: uRef)
            return nil
        })
    }
    
    func rejectJoinRequestTransaction(familyId fid: String, uid: String) async throws {
        let db = Firestore.firestore()
        let fRef = Collections.families.document(fid)
        let now = Date()
        
        _ = try await db.runTransaction({ txn, errorPointer -> Any? in
            do { _ = try txn.getDocument(fRef) }
            catch let err as NSError { errorPointer?.pointee = err; return nil }
            
            txn.updateData([
                "pendingRequests.\(uid)": FieldValue.delete(),
                "updatedAt": Timestamp(date: now)
            ], forDocument: fRef)
            return nil
        })
    }
    
    // Optional: rotate join code (organizer)
    func rotateJoinCodeTransaction(fid: String) async throws {
        let db = Firestore.firestore()
        let fRef = Collections.families.document(fid)
        let now = Date()
        let newCode = FamilyRepository.generateJoinCode()
        
        _ = try await db.runTransaction({ txn, errorPointer -> Any? in
            do { _ = try txn.getDocument(fRef) }
            catch let err as NSError { errorPointer?.pointee = err; return nil }
            
            txn.updateData([
                "joinCode": newCode,
                "updatedAt": Timestamp(date: now)
            ], forDocument: fRef)
            return nil
        })
    }
}
