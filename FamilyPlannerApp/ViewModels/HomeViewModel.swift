//
//  HomeViewModel.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/4/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore

// ViewModel for the Home screen
@MainActor
final class HomeViewModel: ObservableObject {
    // Header
    @Published var greeting: String = ""
    @Published var displayName: String = ""
    @Published var familyName: String = ""
    @Published private(set) var isOrganizer = false
    
    // Cards
    @Published var reminders: [ReminderItem] = []
    @Published var weather: WeatherSummary? = nil // Set from your WeatherKit provider
    @Published var todayString: String = ""
    
    @Published var isLoading: Bool = true
    
    //    private var remindersListener: ListenerRegistration?
    
    //    deinit { remindersListener?.remove() }
    
    init() { }
    
    func onAppear(session: AppSession?) {        
        todayString = Self.formattedToday()
        // Pull header values straight from your AppSession
        refreshHeader(session: session)
        
        // Start Firestore listener for reminders (family-scoped)
        let familyId = session?.userDoc?.familyId
        let userId = session?.userDoc?.id ?? session?.userDoc?.id
        //        startRemindersListener(familyId: familyId, userId: userId)
        
        // Weather: plug in your WeatherKit provider here, e.g. set `self.weather`
        // Task { @MainActor in self.weather = await weatherProvider.summaryForHome() }
        
        isLoading = false
    }
    
    // MARK: - Firestore
    
    //    private func startRemindersListener(familyId: String?, userId: String?) {
    //        remindersListener?.remove()
    //        guard let fid = familyId, !fid.isEmpty else { return }
    //
    //        let db = Firestore.firestore()
    //        var query: Query = db
    //            .collection("families")
    //            .document(fid)
    //            .collection("reminders")
    //            .whereField("isCompleted", isEqualTo: false)
    //
    //        if let uid = userId, !uid.isEmpty {
    //            // Optional per-user filter if you store an `assignedTo` array in reminder docs
    //            query = query.whereField("assignedTo", arrayContains: uid)
    //        }
    //
    //        query = query.order(by: "dueAt", descending: false).limit(to: 8)
    //
    //        remindersListener = query.addSnapshotListener { [weak self] snapshot, error in
    //            if let error = error {
    //                print("[HomeViewModel] reminders listener error: \(error)")
    //                Task { @MainActor in self?.reminders = [] }
    //                return
    //            }
    //            guard let docs = snapshot?.documents else {
    //                Task { @MainActor in self?.reminders = [] }
    //                return
    //            }
    //
    //            let items: [ReminderItem] = docs.compactMap { doc in
    //                do {
    //                    let dto = try doc.data(as: FirestoreReminderDTO.self)
    //                    return ReminderItem(
    //                        id: doc.documentID,
    //                        title: dto.title,
    //                        due: dto.dueAt,
    //                        isCompleted: dto.isCompleted
    //                    )
    //                } catch {
    //                    print("[HomeViewModel] decode error: \(error)")
    //                    return nil
    //                }
    //            }
    //            Task { @MainActor in self?.reminders = items }
    //        }
    //    }
    
    // Refresh when AppSession changes
    func refreshHeader(session: AppSession?) {
        if let user = session?.userDoc {
            let name = (user.displayName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            displayName = name.isEmpty ? (user.email ?? "") : name
            print(displayName)
            print(user.memberships)
        } else {
            displayName = ""
        }
        
        familyName = session?.familyDoc?.name ?? "No Family Selected"
        greeting = Self.makeGreeting(now: Date())
    }
    
    // MARK: - Helpers
    
    private static func formattedToday() -> String {
        let df = DateFormatter()
        df.dateStyle = .full
        df.timeStyle = .none
        return df.string(from: Date())
    }
    
    private static func makeGreeting(now: Date) -> String {
        let hour = Calendar.current.component(.hour, from: now)
        switch hour {
        case 5..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        case 17..<22: return "Good evening,"
        default: return "Hello,"
        }
    }
    
    // MARK: - Toolbar helpers (no extra VM required)
    
    func isOrganizer(session: AppSession) -> Bool {
        guard let me = session.userDoc?.id, let fam = session.familyDoc else { return false }
         
        return fam.organizerId.contains(me)
    }
    
    func switchFamily(to id: String, session: AppSession) {
        Task {
            guard let uid = session.userDoc?.id else { return }
            try? await Collections.users.document(uid).updateData([
                "currentFamilyId": id,
                "updatedAt": Timestamp(date: Date())
            ])
            
            await session.performRefresh()  // simple wrapper that calls your refreshState(initialEvent: false)
        }
    }
    
    func presentNewFamily() {
        // show create-family sheet, or inline create:
        // Task { let newId = try await createFamily(); switchFamily(to: newId) }
    }
    
    func presentManageMembers() {
        // toggle @State to show a Manage Members sheet
    }
    
    func presentInvite() {
        // toggle @State to show Invite sheet
    }
    
    func routeToProfile() {
        // navigate to profile
    }
    
    func routeToSettings() {
        // navigate to settings
    }
}

// Firestore DTO local to this file to avoid extra files
private struct FirestoreReminderDTO: Codable {
    var title: String
    var dueAt: Date?
    var isCompleted: Bool
    var assignedTo: [String]? // optional
}


//    // Published property so the view updates when username changes
//    @Published var username: String = "Toby"  // This would later be pulled from Firebase
//
//    // Computed property to return a greeting based on the time of day
//    var greeting: String {
//        let hour = Calendar.current.component(.hour, from: Date())
//        switch hour {
//        case 5..<12: return "Good morning"
//        case 12..<17: return "Good afternoon"
//        case 17..<22: return "Good evening"
//        default: return "Welcome back"
//        }
//    }
//}
