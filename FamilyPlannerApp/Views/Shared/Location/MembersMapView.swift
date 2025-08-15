//
//  MembersMapView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/12/25.
//

import SwiftUI
import MapKit
import FirebaseFirestore

struct MembersMapView: View {
    @EnvironmentObject var session: AppSession
    @State private var camera: MapCameraPosition = .automatic
    
    var body: some View {
        Map(position: $camera) {
            // Everyone’s pin
            ForEach(session.memberLocations) { m in
                Annotation(m.displayName, coordinate: m.coordinate) {
                    VStack(spacing: 4) {
                        // Pin head
                        Image(systemName: "mappin")
                            .imageScale(.large)
                        // Label
                        Text(m.displayName)
                            .font(.caption2)
                            .padding(4)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            
            UserAnnotation()
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapPitchToggle()
            MapScaleView()
        }
        .onAppear {
            fitToMembers()
        }
        .onChange(of: session.memberLocations) { _, _ in
            fitToMembers()
        }
    }
    
    private func fitToMembers() {
        let coords = session.memberLocations.map(\.coordinate)
        guard !coords.isEmpty else { return }
        let lats = coords.map(\.latitude)
        let lons = coords.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.02, (maxLat - minLat) * 1.6),
            longitudeDelta: max(0.02, (maxLon - minLon) * 1.6)
        )
        camera = .region(MKCoordinateRegion(center: center, span: span))
    }
}

#Preview {
    let session = AppSession()
    
    let _ = {
        session.memberLocationsByUID = [
            "1": MemberLocation(id: "1", uid: "1", displayName: "Toby",
                                photoURL: "https://picsum.photos/seed/toby/88",
                                isSharing: true,
                                coord: GeoPoint(latitude: 36.8508, longitude: -76.2859),
                                lastUpdated: nil),
            "2": MemberLocation(id: "2", uid: "2", displayName: "Alex",
                                photoURL: "https://picsum.photos/seed/alex/88",
                                isSharing: true,
                                coord: GeoPoint(latitude: 36.8520, longitude: -76.2875),
                                lastUpdated: nil),
            "3": MemberLocation(id: "3", uid: "3", displayName: "Sam",
                                photoURL: "https://picsum.photos/seed/sam/88",
                                isSharing: true,
                                coord: GeoPoint(latitude: 40.7128, longitude: -74.0060),
                                lastUpdated: nil)
        ]
    }()
    
    MembersMapView()
        .environmentObject(session)
        .frame(height: 300)
}
