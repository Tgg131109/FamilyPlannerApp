//
//  MemberModel.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/10/25.
//

import Foundation
import CoreLocation
import FirebaseFirestore

struct MemberMeta: Codable {
    var role: UserRole
    var joinedAt: Date
}

struct PendingMeta: Codable {
    var email: String
    var requestedAt: Date
}

struct MemberLocation: Identifiable, Codable {
    @DocumentID var id: String?        // uid
    var uid: String
    var displayName: String
    var photoURL: String?
    var isSharing: Bool
    var coord: GeoPoint
    var lastUpdated: Timestamp?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
    }
}

extension MemberLocation: Equatable {
    static func == (lhs: MemberLocation, rhs: MemberLocation) -> Bool {
        // Treat two member locations as the same when identity and core fields match
        (lhs.id ?? lhs.uid) == (rhs.id ?? rhs.uid)
        && lhs.isSharing == rhs.isSharing
        && lhs.coord.latitude == rhs.coord.latitude
        && lhs.coord.longitude == rhs.coord.longitude
        && (lhs.lastUpdated?.seconds ?? 0) == (rhs.lastUpdated?.seconds ?? 0)
    }
}
