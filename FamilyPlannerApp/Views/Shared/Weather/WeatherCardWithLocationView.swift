//
//  WeatherCardWithLocationView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/9/25.
//

import SwiftUI
import CoreLocation

/// Drop-in wrapper that handles permissions + feeds coordinates into WeatherCardView.
struct WeatherCardWithLocationView: View {
    @StateObject private var location = LocationManager()

    // Dependency injection: pass your weather provider (Mock or WeatherKit)
    let provider: WeatherProviding

    var body: some View {
        Group {
            switch location.authorizationStatus {
            case .notDetermined:
                // First-time users see a simple prompt
                VStack(spacing: 12) {
                    Text("Weather for Your Area")
                        .font(.headline)
                    Text("We’ll use your location to show accurate conditions.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Allow Location") {
                        location.requestWhenInUseAuthorization()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()

            case .denied, .restricted:
                // Helpful guidance + shortcut to Settings
                VStack(spacing: 12) {
                    Text("Location Disabled")
                        .font(.headline)
                    Text("Enable Location in Settings to see local weather.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    HStack(spacing: 12) {
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)

                        Button("Retry") {
                            location.requestWhenInUseAuthorization()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()

            case .authorizedWhenInUse, .authorizedAlways:
                if let coord = location.lastCoordinate {
                    // We have coordinates → render the actual Weather Card
                    WeatherCardView.with(provider: provider, coordinate: coord)
                } else {
                    // Authorized but no fix yet → start and show a spinner
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Getting your location…").font(.footnote).foregroundStyle(.secondary)
                    }
                    .task {
                        // Triggers a one-time start if not already updating
                        location.startUpdates()
                    }
                    .padding()
                }

            @unknown default:
                Text("Unknown location state").foregroundStyle(.secondary)
            }
        }
        .onAppear {
            // Kick things off on first appearance
            if location.authorizationStatus == .authorizedWhenInUse || location.authorizationStatus == .authorizedAlways {
                location.startUpdates()
            }
        }
        .frame(maxWidth: .infinity)
        .onDisappear {
            // Optional: stop updates to save battery if this card is transient
            location.stopUpdates()
        }
        // Surface any runtime errors
        .overlay(alignment: .bottomLeading) {
            if let err = location.errorMessage {
                Text(err)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(8)
                    .background(.red.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(8)
            }
        }
    }
}

// MARK: - Preview
#Preview("Mock • Uses Norfolk Coord") {
    WeatherCardWithLocationView(
        provider: MockWeatherService() // swap with WeatherKitService() when ready (iOS 16+)
    )
    .padding()
    .background(Color(.systemBackground))
}
