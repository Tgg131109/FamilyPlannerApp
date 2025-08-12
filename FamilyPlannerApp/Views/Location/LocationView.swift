//
//  LocationView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/12/25.
//

import SwiftUI
import FirebaseFirestore

struct LocationView: View {
    @EnvironmentObject var session: AppSession
    @EnvironmentObject var location: GlobalLocationCoordinator

    @State private var isSharing = true
    @State private var writeTimer: Timer?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Toggle("Share my location", isOn: $isSharing)
                    .toggleStyle(SwitchToggleStyle())
                Spacer()
            }
            .padding()

            MembersMapView()
        }
        .onAppear {
            location.startUpdates()
            startWriter()
        }
        .onDisappear {
            writeTimer?.invalidate()
            writeTimer = nil
        }
        .onChange(of: isSharing) { _, on in
            if on { startWriter() }
            else {
                writeTimer?.invalidate()
                writeTimer = nil
                Task { await session.stopSharingMyLocation() }
            }
        }
        // Push an immediate write when the coordinate changes (rounded by your coordinator)
        .onChange(of: location.lastCoordinateKey) { _, _ in
            guard isSharing else { return }
            
            Task {
                await session.upsertMyLocationIfNeeded(using: location)
            }
        }
    }

    private func startWriter() {
        writeTimer?.invalidate()
        guard isSharing else { return }
        // Keep-alive every ~20s (writer also throttles itself)
        writeTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { _ in
            Task { await session.upsertMyLocationIfNeeded(using: location) }
        }
    }
}

#Preview {
    let session = AppSession()
    session.memberLocations = [
        MemberLocation(
            id: "1",
            uid: "1",
            displayName: "Toby",
            photoURL: "https://picsum.photos/seed/toby/88",
            isSharing: true,
            coord: GeoPoint(latitude: 36.8508, longitude: -76.2859),
            lastUpdated: nil
        ),
        MemberLocation(
            id: "2",
            uid: "2",
            displayName: "Alex",
            photoURL: "https://picsum.photos/seed/alex/88",
            isSharing: true,
            coord: GeoPoint(latitude: 36.8520, longitude: -76.2875),
            lastUpdated: nil
        ),
        MemberLocation(
            id: "3",
            uid: "3",
            displayName: "Sam",
            photoURL: "https://picsum.photos/seed/sam/88",
            isSharing: true,
            coord: GeoPoint(latitude: 40.7128, longitude: -74.0060), // New York City
            lastUpdated: nil
        )
    ]
    
    return LocationView()
        .environmentObject(session)
        .environmentObject(GlobalLocationCoordinator.preview(
            lat: 36.8508,
            lon: -76.2859
        ))
}
