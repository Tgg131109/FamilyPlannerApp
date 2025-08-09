//
//  GlobalLocationCoordinator.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/9/25.
//

import Foundation
import CoreLocation
import Combine

/// App-wide location coordinator that:
/// - manages permission + location updates
/// - exposes the latest coordinate/authorization via @Published
/// - centralizes throttling rules for location-based fetches
///
/// Inject this as an EnvironmentObject at app launch.
final class GlobalLocationCoordinator: NSObject, ObservableObject {
    
    // MARK: - Public observable state
    
    /// Authorization state the UI can react to.
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    /// Most recent coordinate (nil until the first fix).
    @Published var lastCoordinate: CLLocationCoordinate2D?
    
    /// Human-friendly error text (shown in UI if you like).
    @Published var errorMessage: String?
    
    /// Latest non-generic name we’ve resolved
    @Published var lastPlaceName: String?
    
    // MARK: - Throttling configuration (tweak app-wide)
    /// Only allow a new fetch if the user moved at least this many meters.
    var minDistanceMeters: CLLocationDistance = 750
    
    /// Or if this much time passed since the last fetch.
    var minTimeInterval: TimeInterval = 10 * 60
    
    // MARK: - Private
    private let manager = CLLocationManager()
    private var lastFetchCoordinate: CLLocationCoordinate2D?
    private var lastFetchDate: Date?
    
    // 🔹 Reverse-geocode cache: roundedCoordKey -> "City, ST"
    private var placeNameCache: [String: String] = [:]
    private let geocoder = CLGeocoder()
    
    // MARK: - Init
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 300 // reduce churn; adjust to taste
        manager.activityType = .other
        authorizationStatus = manager.authorizationStatus
    }
    
    // MARK: - Permissions / lifecycle
    
    /// Ask the user for "When In Use" authorization. Safe to call multiple times.
    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
    
    /// Begin active location updates (foreground).
    func startUpdates() {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "Location access is denied. Enable it in Settings."
        @unknown default:
            errorMessage = "Unknown location permission state."
        }
    }
    
    /// Stop updates to save battery (useful if a screen goes off-screen).
    func stopUpdates() {
        manager.stopUpdatingLocation()
    }
    
    // MARK: - Throttle API (shared across features)
    
    /// Should this feature perform a network fetch now?
    func shouldFetchNow(for coord: CLLocationCoordinate2D) -> Bool {
        // Distance gate
        let farEnough: Bool = {
            guard let last = lastFetchCoordinate else { return true }
            let d = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                .distance(from: CLLocation(latitude: last.latitude, longitude: last.longitude))
            return d >= minDistanceMeters
        }()
        
        // Time gate
        let staleEnough: Bool = {
            guard let last = lastFetchDate else { return true }
            return Date().timeIntervalSince(last) >= minTimeInterval
        }()
        
        return farEnough || staleEnough
    }
    
    /// Call after you perform the fetch to record the moment + position.
    func recordFetch(for coord: CLLocationCoordinate2D) {
        lastFetchCoordinate = coord
        lastFetchDate = Date()
    }
    
    /// Reset throttling (e.g., user pulls-to-refresh).
    func resetThrottle() {
        lastFetchCoordinate = nil
        lastFetchDate = nil
    }
    
    // MARK: - Reverse geocode with cache
    /// Short key like "36.851,-76.286" to coalesce nearby lookups.
    private func roundedKey(for coord: CLLocationCoordinate2D, decimals: Int = 3) -> String {
        let pow10 = pow(10.0, Double(decimals))
        let lat = (coord.latitude  * pow10).rounded() / pow10
        let lon = (coord.longitude * pow10).rounded() / pow10
        return "\(lat),\(lon)"
    }
    
    /// Returns a friendly "City, ST" (US) or "City, Country". Cached by rounded coordinate.
    @MainActor
    func placeName(for coord: CLLocationCoordinate2D) async -> String {
        let key = roundedKey(for: coord, decimals: 4) // a bit more precise to avoid stale names

        // If we already have a good name cached for this area, return it
        if let cached = placeNameCache[key] { return cached }

        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            let pm = placemarks.first
            let city = pm?.locality ?? pm?.subAdministrativeArea
            let state = pm?.administrativeArea
            let countryCode = pm?.isoCountryCode
            let country = pm?.country

            let name: String = {
                if let city, let state, (countryCode == "US" || country == "United States") {
                    return "\(city), \(state)"
                } else if let city, let country {
                    return "\(city), \(country)"
                } else if let raw = pm?.name { return raw }
                else { return "Current Location" }
            }()

            // ✅ Only cache/publish *real* names (not the generic fallback).
            if name != "Current Location" {
                placeNameCache[key] = name
                lastPlaceName = name
                // tiny cap to avoid unbounded growth
                if placeNameCache.count > 200 { placeNameCache.remove(at: placeNameCache.startIndex) }
            }
            
            return name
        } catch {
            // Don’t cache the fallback; just return it
            return "Current Location"
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension GlobalLocationCoordinator: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            errorMessage = nil
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.last {
            lastCoordinate = loc.coordinate
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = error.localizedDescription
    }
}

// MARK: - Preview convenience
extension GlobalLocationCoordinator {
    /// A mocked coordinator you can use in previews.
    static func preview(lat: Double = 36.8508, lon: Double = -76.2859) -> GlobalLocationCoordinator {
        let c = GlobalLocationCoordinator()
        c.authorizationStatus = .authorizedWhenInUse
        c.lastCoordinate = .init(latitude: lat, longitude: lon)
        return c
    }
}
