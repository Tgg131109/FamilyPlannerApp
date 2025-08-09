//
//  WeatherService.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/9/25.
//

import Foundation
import CoreLocation

/// Domain model the UI needs (kept small & stable)
struct WeatherSummary: Equatable {
    let locationName: String
    let condition: String          // e.g., "Clear", "Rain", "Cloudy"
    let symbolName: String         // SF Symbol for the condition
    let temperature: Double        // Current temp (°F/°C — your choice)
    let high: Double               // Daily high
    let low: Double                // Daily low
    let precipitationChance: Double // 0.0...1.0
    let windMph: Double
}

/// Protocol so the view model doesn’t care where data comes from (WeatherKit, mock, etc.)
protocol WeatherProviding {
    /// Fetch a compact summary for given coordinates
    func fetchSummary(for coordinate: CLLocationCoordinate2D) async throws -> WeatherSummary
}

/// Simple mock service for previews, offline work, and tests
struct MockWeatherService: WeatherProviding {
    func fetchSummary(for coordinate: CLLocationCoordinate2D) async throws -> WeatherSummary {
        // Simulate small delay to exercise loading state
        try await Task.sleep(nanoseconds: 300_000_000)
        return WeatherSummary(
            locationName: "Norfolk, VA",
            condition: "Partly Cloudy",
            symbolName: "cloud.sun.fill",
            temperature: 77,
            high: 82,
            low: 68,
            precipitationChance: 0.15,
            windMph: 7
        )
    }
}

#if canImport(WeatherKit)
import WeatherKit

/// WeatherKit-backed provider (requires iOS 16+, Apple entitlement, and Apple ID in Xcode)
@available(iOS 16.0, *)
final class WeatherKitService: WeatherProviding {
    private let service = WeatherService.shared

    func fetchSummary(for coordinate: CLLocationCoordinate2D) async throws -> WeatherSummary {
        let loc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let weather = try await service.weather(for: loc)

        // Pick a symbol based on the current condition
        let symbol = weather.currentWeather.symbolName // WeatherKit already maps to SF Symbols

        // Use the first daily forecast for hi/lo
        let today = weather.dailyForecast.first
        let hi = today?.highTemperature.value ?? weather.currentWeather.temperature.value
        let lo = today?.lowTemperature.value ?? weather.currentWeather.temperature.value

        // Try to derive a friendly location label; you can pass one in instead if you prefer
        let locationName = "Current Location"

        return WeatherSummary(
            locationName: locationName,
            condition: weather.currentWeather.condition.description, // e.g., "Clear"
            symbolName: symbol,
            temperature: weather.currentWeather.temperature.value,
            high: hi,
            low: lo,
            precipitationChance: (today?.precipitationChance ?? 0.0),
            windMph: weather.currentWeather.wind.speed.converted(to: .milesPerHour).value
        )
    }
}
#endif
