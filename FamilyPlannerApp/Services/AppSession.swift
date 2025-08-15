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
    @Published var coordinator : GlobalLocationCoordinator
    @Published private(set) var route: AppRoute = .splash
    @Published private(set) var userDoc: UserModel?
    @Published private(set) var familyDoc: FamilyModel?
    @Published var errorMessage: String?
    @Published var userFamilies: [FamilyModel] = []         // Household switcher
    //    @Published var memberLocations: [MemberLocation] = []   // Household locations
    
    private let auth: AuthServicing
    private let users: UserRepositorying
    private let families: FamilyRepositorying
    private var authHandle: AuthStateDidChangeListenerHandle?
    private var didReceiveInitialAuthEvent = false
    
    // Household switcher
    private var familyMap: [String: FamilyModel] = [:]
    private var familyListeners: [String: ListenerRegistration] = [:]
    
    // Household locations - Keep exactly one listener alive (for the active family)
    private var memberLocationsListener: ListenerRegistration?
    private var memberLocationsFamilyId: String?
    private var lastLocationWriteAt: Date?
    
    // Current household's live locations keyed by member uid (stable IDs for Map)
    @Published var memberLocationsByUID: [String: MemberLocation] = [:]
    
    var memberLocations: [MemberLocation] {
        Array(memberLocationsByUID.values)
    }
    
    // Cache locations per family to avoid blanking the map on switch
    // familyId -> (uid -> location)
    private var memberLocationsCache: [String: [String: MemberLocation]] = [:]
    
    init(
        auth: AuthServicing? = nil,
        users: UserRepositorying? = nil,
        families: FamilyRepositorying? = nil,
        coordinator: GlobalLocationCoordinator? = nil
    ) {
        self.auth = auth ?? FirebaseAuthService()
        self.users = users ?? UserRepository()
        self.families = families ?? FamilyRepository()
        self.coordinator = coordinator ?? GlobalLocationCoordinator()
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
                    //                    await fetchFamiliesForMembershipsOnce(membershipIds)
                     attachFamilyListeners(for: Set(membershipIds))   // <- if you want live updates instead
                    
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
            print("Subscribing to member locations for \(id)")
            self.subscribeToMemberLocations(for: id)
        } else {
            print(">>> Unsubscribing from member locations")
            self.stopMemberLocations()
        }
    }
    
    func switchCurrentFamily(to fid: String) async {
        guard let uid = auth.currentUID else { return }
        
        // If already selected, nothing to do
        if familyDoc?.id == fid { return }
        
        // Optimistically reflect the new currentFamilyId in-memory
        if var u = userDoc { u.currentFamilyId = fid; userDoc = u }
        
        // Snap UI to a known FamilyModel immediately if we have it
        if let known = userFamilies.first(where: { $0.id == fid }) {
            familyDoc = known
        }
        
        // Swap the location listener now (prevents map blanking)
        subscribeToMemberLocations(for: fid)
        
        // Persist the selection to Firestore
        if let uid = auth.currentUID {
            try? await Collections.users.document(uid).updateData([
                "currentFamilyId": fid,
                "updatedAt": Timestamp(date: Date())
            ])
        }
        
        // Fetch the latest family doc once and surface it
        if let snap = try? await Collections.families.document(fid).getDocument(),
           var fam = try? snap.data(as: FamilyModel.self) {
            fam.id = snap.documentID
            familyDoc = fam
        }
        
        await upsertMyLocationIfNeeded()
        
//        if let c = coordinate ?? latestCoordinate {
//            let name = (userDoc?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
//            ?? (userDoc?.email ?? "Me")
//            await upsertMyLocationIfNeeded()
//        }
        
        //        try? await Collections.users.document(uid).updateData([
        //            "currentFamilyId": fid,
        //            "updatedAt": Timestamp(date: Date())
        //        ])
        //
        //        // Only fetch that family's doc and update listeners
        //        let fSnap = try? await Collections.families.document(fid).getDocument()
        //
        //        if var fam = try? fSnap?.data(as: FamilyModel.self) {
        //            fam.id = fSnap?.documentID
        //            self.familyDoc = fam
        //
        //            subscribeToMemberLocations(for: fid)
        //        }
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
        // If already watching this family, do nothing
        if memberLocationsFamilyId == familyId { return }
        
        // Clean up any prior family listener
        memberLocationsListener?.remove()
        memberLocationsListener = nil
        //        memberLocations.removeAll()
        memberLocationsFamilyId = familyId
        
        // Seed current map state from cache so labels don't blink
        memberLocationsByUID = memberLocationsCache[familyId] ?? memberLocationsByUID
        
        // Attach new listener
        memberLocationsListener = Collections.families
            .document(familyId)
            .collection("memberLocations")
            .addSnapshotListener { [weak self] snap, err in
                guard let self, let snap else { return }
                
                // Merge by document change to keep annotation IDs stable
                var next = self.memberLocationsByUID
                for change in snap.documentChanges {
                    let uid = change.document.documentID
                    switch change.type {
                    case .added, .modified:
                        if let loc = try? change.document.data(as: MemberLocation.self) {
                            next[uid] = loc
                        }
                    case .removed:
                        next.removeValue(forKey: uid)
                    }
                }
                
                // Publish + cache for this family
                self.memberLocationsByUID = next
                self.memberLocationsCache[familyId] = next
            }
    }
    
    func stopMemberLocations() {
        memberLocationsListener?.remove()
        memberLocationsListener = nil
        //        memberLocations.removeAll()
        
        familyDoc = nil
        userFamilies.removeAll()
        memberLocationsByUID.removeAll()
    }
    
    func upsertMyLocationIfNeeded() async {
        guard let uid = auth.currentUID,
              let fid = userDoc?.currentFamilyId ?? familyDoc?.id,
              let myCoord = coordinator.lastCoordinate
        else { return }
        
        // Optional: honor the global throttle heuristic
        guard coordinator.shouldFetchNow(for: myCoord) else { return }
        
        guard let memberships = userDoc?.memberships, let uid = userDoc?.id else { return }
        let db = Firestore.firestore()
        // Extra: hard time throttle to avoid chatty writes
        let now = Date()
        
        if let last = lastLocationWriteAt, now.timeIntervalSince(last) < 20 { return }
        
        lastLocationWriteAt = now
        
        let displayName = userDoc?.displayName ?? "Member"
        let photo = userDoc?.photoURL ?? Auth.auth().currentUser?.photoURL?.absoluteString
        let batch = db.batch()
        
        for (fid, _) in memberships {
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
            
            let ref = Collections.families
                .document(fid)
                .collection("memberLocations")
                .document(uid)
            
            batch.setData(data, forDocument: ref, merge: true)
        }
        
        do { try await batch.commit() } catch {
            // optional: surface an error if you track one
            print("upsertMyLocationToAllFamilies failed:", error.localizedDescription)
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

#if DEBUG
@MainActor
extension AppSession {
    /// Preview hook: seed session with fake data
    func loadPreviewState(user: UserModel?, family: FamilyModel?, families: [FamilyModel]) {
        self.userDoc = user
        self.familyDoc = family
        self.userFamilies = families   // rename to your actual array prop if different
        self.route = .active
    }
}
#endif

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
