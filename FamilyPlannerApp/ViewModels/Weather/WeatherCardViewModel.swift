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
            
            // Convert to your preferred units (if needed)
            let tempF = data.temperature
            let hiF   = data.high
            let loF   = data.low
            let windMph = data.windMph
            
            // ✅ Preserve any existing non‑empty name
            let preservedName = (summary?.locationName.isEmpty == false) ? summary!.locationName : nil
            
            // If we have a summary already, update its fields in place
            if var s = summary {
                s.condition = data.condition
                s.symbolName = data.symbolName
                s.temperature = tempF
                s.high = hiF
                s.low = loF
                s.precipitationChance = data.precipitationChance
                s.windMph = windMph
                if let preservedName, preservedName != "Current Location" {
                    s.locationName = preservedName
                }
                summary = s
            } else {
                // First time: set summary; keep provider's name only as a fallback
                summary = WeatherSummary(
                    locationName: preservedName ?? data.locationName, // keep an existing name if we had one
                    condition: data.condition,
                    symbolName: data.symbolName,
                    temperature: tempF,
                    high: hiF,
                    low: loF,
                    precipitationChance: data.precipitationChance,
                    windMph: windMph
                )
            }        } catch {
                errorText = error.localizedDescription
            }
        
        isLoading = false
    }
    
    /// Lightweight formatters the view can use
    func tempString(_ t: Double, unit: String = "°F") -> String { "\(Int(round(t)))\(unit)" }
    func percentString(_ p: Double) -> String { "\(Int(round(p * 100)))%" }
    func windString(_ mph: Double) -> String { "\(Int(round(mph))) mph" }
}
