//
//  AppSession.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/9/25.
//

import Foundation
import FirebaseAuth
import FirebaseCore

@MainActor
final class AppSession: ObservableObject {
    @Published private(set) var route: AppRoute = .splash
    @Published private(set) var userDoc: UserModel?
    @Published private(set) var familyDoc: FamilyModel?
    @Published var errorMessage: String?
    
    private let auth: AuthServicing
    private let users: UserRepositorying
    private let families: FamilyRepositorying
    private var authHandle: AuthStateDidChangeListenerHandle?
    private var didReceiveInitialAuthEvent = false
    
    init(
        auth: AuthServicing? = nil,
        users: UserRepositorying? = nil,
        families: FamilyRepositorying? = nil
    ) {
        self.auth = auth ?? FirebaseAuthService()
        self.users = users ?? UserRepository()
        self.families = families ?? FamilyRepository()
    }
    
    deinit { if let h = authHandle { Auth.auth().removeStateDidChangeListener(h) } }
    
    func start() async {
        // Show splash until we receive the first auth event
        route = .splash
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, _ in
            Task { await self?.refreshState(initialEvent: true) }
        }
        await refreshState(initialEvent: false)
    }
    
    private func refreshState(initialEvent: Bool) async {
        if let uid = auth.currentUID {
            do {
                // Load or bootstrap user profile
                if let existing = try await users.get(uid: uid) {
                    self.userDoc = existing
                    // backfill user in the background
                    await backfillUserIfNeeded(existing)
                } else {
                    self.userDoc = nil
                }

                route = computeRoute()

                // If active, load & backfill family too
                if case .active = route, let fid = userDoc?.familyId {
                    let fSnap = try await Collections.families.document(fid).getDocument()
                    if let fam = try? fSnap.data(as: FamilyModel.self) {
                        self.familyDoc = fam
                        await backfillFamilyIfNeeded(fam, fid: fid, ensureMember: uid)
                    } else {
                        // If family decode fails, you could optionally drop to needsFamilySetup:
                        // route = .needsFamilySetup(role: userDoc?.role ?? .organizer)
                    }
                } else {
                    self.familyDoc = nil
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        } else {
            userDoc = nil; familyDoc = nil
            if didReceiveInitialAuthEvent || initialEvent { route = .signedOut } else { route = .splash }
        }
    }

    
    private func computeRoute() -> AppRoute {
        guard let _ = auth.currentUID else { return .signedOut }
        guard let user = userDoc else { return .signedInNoProfile }
        guard user.status == .active else { return .pendingMembership }
        if user.familyId == nil { return .needsFamilySetup(role: user.role) }
        return .active
    }
    
    // MARK: - Auth actions
    func signIn(email: String, password: String) async {
        do {
            try await auth.signIn(email: email, password: password)
            
            await refreshState(initialEvent: false)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func signUp(email: String, password: String, displayName: String, role: UserRole) async {
        do {
            let uid = try await auth.signUp(email: email, password: password)
            var u = UserModel(uid: uid, email: email, displayName: displayName, role: role)
            
            u.id = uid
            u.providerIds = auth.providerIDs
            
            try await users.upsert(u)
            
            self.userDoc = u
            route = computeRoute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func signOut() { do { try auth.signOut(); Task { await refreshState(initialEvent: false) } } catch { errorMessage = error.localizedDescription } }
    
    // MARK: - Family actions
    func createFamily(name: String) async {
        guard let uid = auth.currentUID else { return }
        do {
            let fid = try await families.createFamilyTransaction(name: name, organizerUID: uid)
            var u = try await users.get(uid: uid)
            u?.familyId = fid
            if let u { try await users.upsert(u); self.userDoc = u }
            route = computeRoute()
            await refreshState(initialEvent: false)
        } catch { errorMessage = error.localizedDescription }
    }
    
    func joinFamily(joinCode: String) async {
        guard let uid = auth.currentUID else { return }
        do {
            let fid = try await families.joinFamilyByCodeTransaction(code: joinCode, uid: uid)
            var u = try await users.get(uid: uid)
            u?.familyId = fid
            if let u { try await users.upsert(u); self.userDoc = u }
            route = computeRoute()
            await refreshState(initialEvent: false)
        } catch { errorMessage = error.localizedDescription }
    }
    
    private func backfillUserIfNeeded(_ user: UserModel) async {
        guard let uid = user.id else { return }
        var patch: [String: Any] = [:]

        // Non-optional now; only backfill arrays/derived fields
        if user.providerIds.isEmpty {
            patch["providerIds"] = []
        }

        // Always keep updatedAt fresh when we touch the doc
        patch["updatedAt"] = Timestamp(date: Date())

        if !patch.isEmpty {
            try? await Collections.users.document(uid).updateData(patch)
        }
    }

    private func backfillFamilyIfNeeded(_ family: FamilyModel, fid: String, ensureMember uid: String?) async {
        var patch: [String: Any] = [:]

        if family.joinCode.isEmpty {
            patch["joinCode"] = FamilyRepository.generateJoinCode()
        }
        if family.members.isEmpty, let uid {
            patch["members.\(uid).role"] = "member"
            patch["members.\(uid).joinedAt"] = Timestamp(date: Date())
        }

        // Always update updatedAt if we’re patching anything
        if !patch.isEmpty {
            patch["updatedAt"] = Timestamp(date: Date())
            try? await Collections.families.document(fid).updateData(patch)
        }
    }
}

///// Holds the signed-in user + family, and reacts to auth state changes.
//@MainActor
//final class AppManager: ObservableObject {
//    @Published var user: UserModel?
//    @Published var family: FamilyModel?
//    @Published var isLoading: Bool = true
//
//    private var handle: AuthStateDidChangeListenerHandle?
//
//    init() {
//        startListening()
//    }
//
//    deinit {
//        if let h = handle { Auth.auth().removeStateDidChangeListener(h) }
//    }
//
//    private func startListening() {
//        handle = Auth.auth().addStateDidChangeListener { [weak self] _, authUser in
//            Task { await self?.loadSession(for: authUser?.uid) }
//        }
//    }
//
//    /// Loads user + family into memory (or clears them if signed out)
//    func loadSession(for uid: String?) async {
//        isLoading = true
//        defer { isLoading = false }
//
//        guard let uid = uid else {
//            user = nil
//            family = nil
//            return
//        }
//
//        // Fetch user doc
//        let u = try? await FirestoreService.shared.fetchUser(uid: uid)
//        user = u
//
//        // Fetch family if present
//        if let famId = u?.familyId {
//            family = try? await FirestoreService.shared.fetchFamily(familyId: famId)
//        } else {
//            family = nil
//        }
//    }
//
//    func signOut() async {
//        do { try FirebaseAuthService.shared.signOut() } catch { /* handle/log if you want */ }
//        await loadSession(for: nil)
//    }
//}
