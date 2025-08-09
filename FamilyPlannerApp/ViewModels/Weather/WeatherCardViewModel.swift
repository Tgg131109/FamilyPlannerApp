//
//  WeatherCardViewModel.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/9/25.
//

import Foundation
import CoreLocation

/// ViewModel handles async loading, error, and formatting for the card
@MainActor
final class WeatherCardViewModel: ObservableObject {
    // Inputs
    private let provider: WeatherProviding
    private let coordinate: CLLocationCoordinate2D

    // Outputs (UI state)
    @Published var isLoading = false
    @Published var errorText: String?
    @Published var summary: WeatherSummary?

    /// Inject a provider (mock/WeatherKit) + coordinates (host screen supplies these)
    init(provider: WeatherProviding, coordinate: CLLocationCoordinate2D) {
        self.provider = provider
        self.coordinate = coordinate
    }

    /// Public load/refresh API
    func load() async {
        isLoading = true
        errorText = nil
        do {
            let data = try await provider.fetchSummary(for: coordinate)
            summary = data
        } catch {
            errorText = error.localizedDescription
        }
        isLoading = false
    }

    /// Lightweight formatters the view can use
    func tempString(_ t: Double, unit: String = "°F") -> String { "\(Int(round(t)))\(unit)" }
    func percentString(_ p: Double) -> String { "\(Int(round(p * 100)))%" }
    func windString(_ mph: Double) -> String { "\(Int(round(mph))) mph" }
}
