//
//  LocationManager.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/9/25.
//

import Foundation
import CoreLocation
import Combine

/// Lightweight, SwiftUI-friendly location manager.
/// - Requests "When In Use" permission
/// - Publishes authorization status and the latest coordinate
/// - Keeps the API simple for views/view models
final class LocationManager: NSObject, ObservableObject {
    // Public outputs the UI can bind to
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastCoordinate: CLLocationCoordinate2D?
    @Published var errorMessage: String?

    // Internal CLLocationManager
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        // Prime current status; useful if user previously granted/denied
        authorizationStatus = manager.authorizationStatus
    }

    /// Ask the user for "When In Use" permission (safe to call multiple times)
    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    /// Start location updates if authorized; otherwise request permission.
    func startUpdates() {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "Location access is denied. You can enable it in Settings."
        @unknown default:
            errorMessage = "Unknown location permission state."
        }
    }

    /// Stop updates to save battery (call when view disappears if you want)
    func stopUpdates() {
        manager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        // Auto-start once granted
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            errorMessage = nil
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Publish last known coordinate
        if let loc = locations.last {
            lastCoordinate = loc.coordinate
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = error.localizedDescription
    }
}
