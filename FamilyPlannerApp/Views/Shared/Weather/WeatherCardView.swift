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
    @StateObject var vm: WeatherCardViewModel
    let greeting: String
    let displayName: String
    let familyName: String
    
    var body: some View {
        ZStack {
            AnimatedMeshGradient()
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            // Subtle, reusable background
            //            LinearGradient(colors: [Color.blue.opacity(0.35), Color.indigo.opacity(0.35)],
            //                           startPoint: .topLeading,
            //                           endPoint: .bottomTrailing)
            //                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            VStack(alignment: .leading, spacing: 10) {
                HeaderCardView(
                    greeting: greeting,
                    displayName: displayName,
                    familyName: familyName
                )
                
                // Weather/temperature row
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: vm.summary?.symbolName ?? "cloud.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(vm.summary?.locationName ?? "—")
                            .font(.headline)
                        Text(vm.summary?.condition ?? "Loading…")
                            .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    Text(vm.tempString(vm.summary?.temperature ?? 0))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
//
//                    // Manual refresh
//                    Button {
//                        Task { await vm.load() }
//                    } label: {
//                        Image(systemName: "arrow.clockwise")
//                            .font(.system(size: 16, weight: .semibold))
//                    }
//                    .buttonStyle(.plain)
//                    .accessibilityLabel("Refresh weather")
                }
                
                // Conditions row
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    // Conditions
                    HStack() {
                        Label(vm.percentString(vm.summary?.precipitationChance ?? 0.0), systemImage: "cloud.rain")
                        
                        Divider().frame(height: 20)
                        
                        Label(vm.windString(vm.summary?.windMph ?? 0.0), systemImage: "wind")
                    }
                    .font(.subheadline)
                    
                    Spacer()
                    
                    // Temperature hi/lo
                    HStack() {
                        Label(vm.tempString(vm.summary?.high ?? 0), systemImage: "arrow.up")
                        
                        Divider().frame(height: 20)
                        
                        Label(vm.tempString(vm.summary?.low ?? 0), systemImage: "arrow.down")
                    }
                    .font(.subheadline)
                }
                
                // Error banner (if any)
                if let err = vm.errorText {
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
        .shadow(radius: 1)
    }
}

/// Handy convenience init so you can create the card inline with a provider + coordinate.
extension WeatherCardView {
    static func with(provider: WeatherProviding,
                     coordinate: CLLocationCoordinate2D) -> WeatherCardView {
        WeatherCardView(vm: WeatherCardViewModel(provider: provider, coordinate: coordinate), greeting: "Good afternoon,", displayName: "Toby", familyName: "Casa Gamble")
    }
}

struct AnimatedMeshGradient: View {
    @State var appear = false
    @State var appear2 = false
    
    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [appear2 ? 0.5 : 1.0, 0.0], [1.0, 0.0],
                [0.0, 0.5], appear ? [0.1, 0.5] : [0.8, 0.2], [1.0, -0.5],
                [0.0, 1.0], [1.0, appear2 ? 2.0 : 1.0], [1.0, 1.0]
            ], colors: [
                appear2 ? .blue.opacity(0.35) : .mint, appear2 ? .indigo.opacity(0.35): .cyan, .orange,
                appear ? .blue.opacity(0.35) : .teal.opacity(0.35), appear ? .cyan : .purple, appear ? .indigo : .purple,
                appear ? .teal : .cyan, appear ? .mint : .blue, appear2 ? .indigo.opacity(0.50) : .blue
            ]
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                appear.toggle()
            }
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                appear2.toggle()
            }
        }
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
