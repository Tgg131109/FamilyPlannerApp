//
//  WeatherCardWithLocationView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/9/25.
//

import SwiftUI
import CoreLocation

/// Wrapper that uses the shared GlobalLocationCoordinator and centralized throttle.
struct WeatherCardWithLocationView: View {
    @EnvironmentObject var location: GlobalLocationCoordinator   // ← shared
    @State private var weatherVM: WeatherCardViewModel?
    private let geocoder = ReverseGeocoder()
    
    let provider: WeatherProviding = {
        if #available(iOS 16.0, *) { return WeatherKitService() }
        else { return MockWeatherService() }
    }()
    
    let greeting: String
    let displayName: String
    let familyName: String
    
    var body: some View {
        Group {
            switch location.authorizationStatus {
            case .notDetermined:
                VStack(spacing: 12) {
                    Text("Weather for Your Area").font(.headline)
                    Text("We’ll use your location to show accurate conditions.")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Allow Location") { location.requestWhenInUseAuthorization() }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
                
            case .denied, .restricted:
                VStack(spacing: 12) {
                    Text("Location Disabled").font(.headline)
                    Text("Enable Location in Settings to see local weather.")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    HStack(spacing: 12) {
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                        Button("Retry") { location.requestWhenInUseAuthorization() }
                            .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                
            case .authorizedWhenInUse, .authorizedAlways:
                if let vm = weatherVM {
                    WeatherCardView(vm: vm, greeting: greeting, displayName: displayName, familyName: familyName)
                } else {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Getting your location…").font(.footnote).foregroundStyle(.secondary)
                    }
                    .padding()
                }
                
            @unknown default:
                Text("Unknown location state").foregroundStyle(.secondary)
            }
        }
        .onAppear {
            // Start updates when visible; the coordinator manages churn and errors.
            if location.authorizationStatus == .authorizedWhenInUse ||
                location.authorizationStatus == .authorizedAlways {
                location.startUpdates()
            }
        }
        .onDisappear { location.stopUpdates() }
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
        // React when the coordinator publishes a new coordinate (rounded key not needed here).
        .task(id: location.lastCoordinate?.latitude ?? 0.0) {
            guard let coord = location.lastCoordinate else { return }
            
            // Respect global throttle
            guard location.shouldFetchNow(for: coord) else { return }
            
            // Create VM once per screen life
            if weatherVM == nil {
                weatherVM = WeatherCardViewModel(provider: provider, coordinate: coord)
            }
            
            // Fetch weather
            if let vm = weatherVM {
                await vm.load()
            }
            
            // Show a quick last known name immediately
            if let quickName = location.lastPlaceName {
                if var s = weatherVM?.summary {
                    s.locationName = quickName
                    weatherVM?.summary = s
                } else {
                    weatherVM?.summary = WeatherSummary(
                        locationName: quickName, condition: "Loading…", symbolName: "cloud.fill",
                        temperature: 0, high: 0, low: 0, precipitationChance: 0, windMph: 0
                    )
                }
            }
            
            // Reverse geocode city/state
            // 1) Show last known place name immediately if we have one
            if let quickName = location.lastPlaceName {
                if var summary = weatherVM?.summary {
                    summary.locationName = quickName
                    weatherVM?.summary = summary
                } else {
                    weatherVM?.summary = WeatherSummary(
                        locationName: quickName, condition: "Loading…", symbolName: "cloud.fill",
                        temperature: 0, high: 0, low: 0, precipitationChance: 0, windMph: 0
                    )
                }
            }
            
            // 2) Resolve (and publish/cache) the current place name
            let freshName = await location.placeName(for: coord)
            
            if freshName != "Current Location" {
                if var s = weatherVM?.summary {
                    s.locationName = freshName
                    weatherVM?.summary = s
                }
            }           
            
            // Record the fetch globally so other features can honor the same throttling window.
            location.recordFetch(for: coord)
        }
    }
}

// MARK: - Preview
#Preview("Global Coordinator + Mock") {
    WeatherCardWithLocationView(greeting: "Good afternoon,", displayName: "Toby", familyName: "Casa Gamble")
        .environmentObject(GlobalLocationCoordinator.preview())
        .padding()
        .background(Color(.systemBackground))
}
