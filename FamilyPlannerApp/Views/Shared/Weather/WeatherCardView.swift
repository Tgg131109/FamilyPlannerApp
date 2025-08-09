//
//  WeatherCardView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/9/25.
//

import SwiftUI
import CoreLocation

/// Plug-and-play Weather Card.
/// Drop this into any screen and pass a ViewModel configured with a provider + coordinate.
struct WeatherCardView: View {
    @StateObject var viewModel: WeatherCardViewModel

    var body: some View {
        ZStack {
            // Subtle, reusable background
            LinearGradient(colors: [Color.blue.opacity(0.35), Color.indigo.opacity(0.35)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 12) {
                    // Leading weather glyph
                    Image(systemName: viewModel.summary?.symbolName ?? "cloud.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.primary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.summary?.locationName ?? "—")
                            .font(.headline)
                        Text(viewModel.summary?.condition ?? "Loading…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Divider().frame(height: 40)
                    
                    Text(viewModel.tempString(viewModel.summary?.temperature ?? 0))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    
                    Spacer()

                    // Manual refresh
                    Button {
                        Task { await viewModel.load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Refresh weather")
                }

                // Temperature row
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    HStack(spacing: 8) {
                        Label(viewModel.tempString(viewModel.summary?.high ?? 0), systemImage: "arrow.up")
                        Label(viewModel.tempString(viewModel.summary?.low ?? 0), systemImage: "arrow.down")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    Spacer()
                    
                    // Details row
                    HStack(spacing: 16) {
                        Label(viewModel.percentString(viewModel.summary?.precipitationChance ?? 0.0), systemImage: "cloud.rain")
                        Label(viewModel.windString(viewModel.summary?.windMph ?? 0.0), systemImage: "wind")
//                        Spacer()
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                // Error banner (if any)
                if let err = viewModel.errorText {
                    Text(err)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 120)
//        .onAppear {
//            // Only auto-load the first time the card appears
//            if viewModel.summary == nil && !viewModel.isLoading {
//                Task { await viewModel.load() }
//            }
//        }
    }
}

/// Handy convenience init so you can create the card inline with a provider + coordinate.
extension WeatherCardView {
    static func with(provider: WeatherProviding,
                     coordinate: CLLocationCoordinate2D) -> WeatherCardView {
        WeatherCardView(viewModel: WeatherCardViewModel(provider: provider, coordinate: coordinate))
    }
}

// MARK: - Preview

#Preview("Mock • Suffolk, VA") {
    WeatherCardView.with(
        provider: MockWeatherService(),
        coordinate: .init(latitude: 36.8508, longitude: -76.2859)
    )
    .padding()
    .background(Color(.systemBackground))
}
