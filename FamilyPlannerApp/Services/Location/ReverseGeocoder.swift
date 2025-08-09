//
//  ReverseGeocoder.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/9/25.
//

import Foundation
import CoreLocation

/// Converts CLLocationCoordinate2D into a human-friendly "City, State/Country" string.
/// Designed to be simple, fast, and safe to call repeatedly.
struct ReverseGeocoder {
    private let geocoder = CLGeocoder()

    /// Reverse geocode a coordinate. Returns a short display string, or a fallback.
    func placeName(for coordinate: CLLocationCoordinate2D) async -> String {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
            // Async reverse geocode (iOS 15+); may throw on network/denied/etc.
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let pm = placemarks.first else { return "Current Location" }

            // Prefer: City, State (US)  → otherwise City, Country  → otherwise a best-effort
            let city = pm.locality ?? pm.subAdministrativeArea
            let state = pm.administrativeArea
            let country = pm.isoCountryCode ?? pm.country

            if let city, let state, !state.isEmpty, country == "US" || (pm.country == "United States") {
                return "\(city), \(state)"
            }
            if let city, let country {
                return "\(city), \(country)"
            }
            if let name = pm.name {
                return name
            }
            return "Current Location"
        } catch {
            // Graceful fallback on failure
            return "Current Location"
        }
    }
}

//#Preview("ReverseGeocoder – Norfolk") {
//    Text("Norfolk, VA") // ReverseGeocoder previews need a runtime location call; this is illustrative.
//        .padding()
//}
