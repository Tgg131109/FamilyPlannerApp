//
//  AppSession.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/9/25.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

@MainActor
final class AppSession: ObservableObject {
    @Published private(set) var route: AppRoute = .splash
    @Published private(set) var userDoc: UserModel?
    @Published private(set) var familyDoc: FamilyModel?
    @Published var errorMessage: String?
    @Published var userFamilies: [FamilyModel] = []         // Household switcher
    @Published var memberLocations: [MemberLocation] = []   // Household locations
    
    private let auth: AuthServicing
    private let users: UserRepositorying
    private let families: FamilyRepositorying
    private var authHandle: AuthStateDidChangeListenerHandle?
    private var didReceiveInitialAuthEvent = false
    
    // Household switcher
    private var familyMap: [String: FamilyModel] = [:]
    private var familyListeners: [String: ListenerRegistration] = [:]
    
    // Household locations
    private var memberLocationsListener: ListenerRegistration?
    private var lastLocationWriteAt: Date?
    
    init(
        auth: AuthServicing? = nil,
        users: UserRepositorying? = nil,
        families: FamilyRepositorying? = nil
    ) {
        self.auth = auth ?? FirebaseAuthService()
        self.users = users ?? UserRepository()
        self.families = families ?? FamilyRepository()
    }
    
    deinit {
        if let h = authHandle {
            Auth.auth().removeStateDidChangeListener(h)
        }
    }
    
    func start() async {
        print("start")
        // Show splash until we receive the first auth event
        route = .splash
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, _ in
            Task { await self?.refreshState(initialEvent: true) }
        }
        
        await refreshState(initialEvent: false)
    }
    
    private var refreshTask: Task<Void, Never>?
    
    func performRefresh() async {
        await refreshState(initialEvent: false) // make refreshState internal or keep private and forward
        // Coalesce overlapping refreshes
        if let t = refreshTask {
            await t.value
            return
        }
        
        refreshTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshState(initialEvent: false)
        }
        
        await refreshTask?.value
        
        refreshTask = nil
    }
    
    private func refreshState(initialEvent: Bool) async {
        if let uid = auth.currentUID {
            do {
                // Load or bootstrap user profile
                if let existing = try await users.get(uid: uid) {
                    self.userDoc = existing
                    await backfillUserIfNeeded(existing)
                } else {
                    self.userDoc = nil
                }
                
                if !didReceiveInitialAuthEvent && initialEvent { didReceiveInitialAuthEvent = true }
                
                route = computeRoute()
                
                // If active, choose the scoped familyId (current or first membership)
                if case .active = route, let user = userDoc {
                    // NEW: get all membership family ids
                    let membershipIds = Array(user.memberships.keys)
                    
                    // Populate families list (pick ONE of the two lines below)
                    await fetchFamiliesForMembershipsOnce(membershipIds)
                    // attachFamilyListeners(for: Set(membershipIds))   // <- if you want live updates instead
                    
                    let fid = userDoc?.currentFamilyId ?? defaultFamilyId(for: user)
                    
                    if let fid {
                        let fSnap = try await Collections.families.document(fid).getDocument()
                        
                        if var fam = try? fSnap.data(as: FamilyModel.self) {
                            fam.id = fSnap.documentID
                            self.familyDoc = fam
                            
                            await backfillFamilyIfNeeded(fam, fid: fid, ensureMember: uid)
                            
                            // If currentFamilyId was nil, persist it
                            if userDoc?.currentFamilyId == nil {
                                try? await Collections.users.document(uid).updateData([
                                    "currentFamilyId": fid,
                                    "updatedAt": Timestamp(date: Date())
                                ])
                                
                                self.userDoc?.currentFamilyId = fid
                            }
                        } else {
                            self.familyDoc = nil
                        }
                    } else {
                        self.familyDoc = nil
                    }
                } else {
                    self.familyDoc = nil
                    self.userFamilies = []
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        } else {
            userDoc = nil
            familyDoc = nil
            userFamilies = []
            route = (didReceiveInitialAuthEvent || initialEvent) ? .signedOut : .splash
        }
        
        if let id = self.familyDoc?.id {
            self.subscribeToMemberLocations(for: id)
        } else {
            self.stopMemberLocations()
        }
    }
    
    private func defaultFamilyId(for user: UserModel) -> String? {
        // Assuming user.memberships: [String: Membership] where Membership has joinedAt: Timestamp/Date
        guard !user.memberships.isEmpty else { return nil }
        
        return user.memberships
            .sorted(by: { lhs, rhs in
                lhs.value.joinedAt < rhs.value.joinedAt
            })
            .first?.key
    }
    
    private func computeRoute() -> AppRoute {
        guard auth.currentUID != nil else { return .signedOut }
        guard let user = userDoc else { return .signedInNoProfile }
        guard user.status == .active else { return .pendingMembership }
        
        if user.memberships.isEmpty { return .needsFamilySetup(role: user.role) }
        
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
    
    func signOut() {
        do {
            try auth.signOut()
            
            Task {
                await refreshState(initialEvent: false)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Family actions
    func createFamily(name: String) async {
        guard let uid = auth.currentUID else { return }
        
        do {
            let fid = try await families.createFamilyTransaction(name: name, organizerUID: uid)
            var u = try await users.get(uid: uid)
            
            u?.familyId = fid
            
            if let u {
                try await users.upsert(u)
                self.userDoc = u
            }
            
            route = computeRoute()
            
            await refreshState(initialEvent: false)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func joinFamily(joinCode: String) async {
        guard let uid = auth.currentUID else { return }
        
        do {
            let fid = try await families.joinFamilyByCodeTransaction(code: joinCode, uid: uid)
            var u = try await users.get(uid: uid)
            
            u?.familyId = fid
            
            if let u {
                try await users.upsert(u)
                
                self.userDoc = u
            }
            
            route = computeRoute()
            
            await refreshState(initialEvent: false)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func backfillUserIfNeeded(_ user: UserModel) async {
        guard let uid = user.id else { return }
        var patch: [String: Any] = [:]
        
        // Migrate legacy single-family field -> memberships/currentFamilyId
        if user.memberships.isEmpty, let legacy = user.familyId, !legacy.isEmpty {
            patch["memberships.\(legacy).role"] = user.role.rawValue
            patch["memberships.\(legacy).joinedAt"] = Timestamp(date: Date())
            patch["currentFamilyId"] = legacy
        }
        
        // Ensure we have a scoped household
        if user.currentFamilyId == nil, !user.memberships.isEmpty {
            if let first = user.memberships.keys.sorted().first {
                patch["currentFamilyId"] = first
            }
        }
        
        // Keep providerIds present; always bump updatedAt if we patch
        if user.providerIds.isEmpty { patch["providerIds"] = [] }
        
        if !patch.isEmpty {
            patch["updatedAt"] = Timestamp(date: Date())
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
        
        if !patch.isEmpty {
            patch["updatedAt"] = Timestamp(date: Date())
            try? await Collections.families.document(fid).updateData(patch)
        }
    }
    
    private func fetchFamiliesForMembershipsOnce(_ ids: [String]) async {
        print("fetching families")
        //        userFamilies.removeAll()
        familyMap.removeAll()
        
        guard !ids.isEmpty else { return }
        
        do {
            for chunk in ids.chunked(into: 10) {
                let snap = try await Collections.families
                    .whereField(FieldPath.documentID(), in: chunk)
                    .getDocuments()
                
                for doc in snap.documents {
                    if var fam = try? doc.data(as: FamilyModel.self) {
                        // Ensure id is present if your model doesn't embed it
                        fam.id = doc.documentID
                        familyMap[doc.documentID] = fam
                    }
                }
            }
            
            userFamilies = familyMap.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    private func attachFamilyListeners(for ids: Set<String>) {
        // remove stale
        for (id, reg) in familyListeners where !ids.contains(id) {
            reg.remove()
            familyListeners[id] = nil
            familyMap[id] = nil
        }
        
        // add missing
        for id in ids where familyListeners[id] == nil {
            let reg = Collections.families.document(id).addSnapshotListener { [weak self] snap, err in
                guard let self, let snap, snap.exists else {
                    self?.familyMap[id] = nil
                    self?.userFamilies = self?.familyMap.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending } ?? []
                    
                    return
                }
                
                if var fam = try? snap.data(as: FamilyModel.self) {
                    fam.id = snap.documentID
                    self.familyMap[id] = fam
                    self.userFamilies = self.familyMap.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                    
                    // keep familyDoc in sync if current
                    if self.familyDoc?.id == id {
                        self.familyDoc = fam
                    }
                }
            }
            
            familyListeners[id] = reg
        }
    }
    
    // MARK: - Family location
    func subscribeToMemberLocations(for familyId: String) {
        // Clean up any prior family listener
        memberLocationsListener?.remove()
        memberLocationsListener = nil
        memberLocations.removeAll()
        
        memberLocationsListener = Collections.families
            .document(familyId)
            .memberLocations
            .whereField("isSharing", isEqualTo: true)
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }
                
                if let err = err {
                    self.errorMessage = err.localizedDescription
                    return
                }
                
                self.memberLocations = snap?.documents.compactMap { doc in
                    try? doc.data(as: MemberLocation.self)
                } ?? []
            }
    }
    
    func stopMemberLocations() {
        memberLocationsListener?.remove()
        memberLocationsListener = nil
        memberLocations.removeAll()
    }
    
    func upsertMyLocationIfNeeded(using coordinator: GlobalLocationCoordinator) async {
        guard let uid = auth.currentUID,
              let fid = userDoc?.currentFamilyId ?? familyDoc?.id,
              let myCoord = coordinator.lastCoordinate
        else { return }
        
        // Optional: honor the global throttle heuristic
        guard coordinator.shouldFetchNow(for: myCoord) else { return }
        
        // Extra: hard time throttle to avoid chatty writes
        let now = Date()
        if let last = lastLocationWriteAt, now.timeIntervalSince(last) < 20 { return }
        lastLocationWriteAt = now
        
        let ref = Collections.families
            .document(fid)
            .memberLocations
            .document(uid)
        
        let displayName = userDoc?.displayName ?? "Member"
        let photo = userDoc?.photoURL ?? Auth.auth().currentUser?.photoURL?.absoluteString
        
        var data: [String: Any] = [
            "uid": uid,
            "displayName": displayName,
            "isSharing": true,
            "coord": GeoPoint(latitude: myCoord.latitude, longitude: myCoord.longitude),
            "lastUpdated": FieldValue.serverTimestamp()
        ]
        
        if let p = photo {
            data["photoURL"] = p
        }
        
        do {
            try await ref.setData(data, merge: true)
            coordinator.recordFetch(for: myCoord)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func stopSharingMyLocation() async {
        guard let uid = auth.currentUID,
              let fid = userDoc?.currentFamilyId ?? familyDoc?.id else { return }
        do {
            try await Collections.families
                .document(fid)
                .memberLocations
                .document(uid)
                .setData(["isSharing": false], merge: true)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
