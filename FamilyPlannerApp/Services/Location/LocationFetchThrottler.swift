//
//  LocationFetchThrottler.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/9/25.
//

import CoreLocation
import Foundation

/// A reusable helper for throttling location-based fetches.
/// Ensures you only fetch when the user has moved far enough or enough time has passed.
final class LocationFetchThrottler {
    private var lastFetchCoord: CLLocationCoordinate2D?
    private var lastFetchDate: Date?

    /// Minimum movement in meters before allowing another fetch.
    private let minDistanceMeters: CLLocationDistance
    /// Minimum time in seconds before allowing another fetch.
    private let minTimeInterval: TimeInterval

    init(minDistanceMeters: CLLocationDistance = 750, minTimeInterval: TimeInterval = 10 * 60) {
        self.minDistanceMeters = minDistanceMeters
        self.minTimeInterval = minTimeInterval
    }

    /// Determines whether you should fetch for the given coordinate and current time.
    func shouldFetch(for coord: CLLocationCoordinate2D) -> Bool {
        let farEnough: Bool = {
            guard let last = lastFetchCoord else { return true }
            let d = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                .distance(from: CLLocation(latitude: last.latitude, longitude: last.longitude))
            return d >= minDistanceMeters
        }()

        let staleEnough: Bool = {
            guard let last = lastFetchDate else { return true }
            return Date().timeIntervalSince(last) >= minTimeInterval
        }()

        return farEnough || staleEnough
    }

    /// Records that a fetch has occurred now for the given coordinate.
    func recordFetch(for coord: CLLocationCoordinate2D) {
        lastFetchCoord = coord
        lastFetchDate = Date()
    }

    /// Resets the throttler state.
    func reset() {
        lastFetchCoord = nil
        lastFetchDate = nil
    }
}
