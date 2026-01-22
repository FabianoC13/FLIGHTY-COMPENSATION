import SwiftUI
import MapKit

/// Interactive 3D globe view showing all flight routes
struct FlightsGlobeView: View {
    let flights: [Flight]
    @Binding var isSatelliteView: Bool
    
    // Default "Space View" constants
    private let defaultCenter = CLLocationCoordinate2D(latitude: 30.0, longitude: -30.0)
    private let defaultDistance: Double = 20_000_000
    
    // Initialize with default Space View
    @State private var mapCameraPosition: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 30.0, longitude: -30.0),
            distance: 20_000_000,
            heading: 0,
            pitch: 0
        )
    )
    
    private var currentMapStyle: MapStyle {
        // Use flat elevation instead of realistic for better performance during drag
        isSatelliteView ? .hybrid(elevation: .flat) : .standard(elevation: .flat, pointsOfInterest: .including([.airport]))
    }

    
    var body: some View {
        Map(position: $mapCameraPosition, interactionModes: [.rotate, .zoom, .pan]) {
            // Draw route lines for each flight
            ForEach(flights) { flight in
                if let depCoord = flight.departureAirport.coordinate,
                   let arrCoord = flight.arrivalAirport.coordinate {
                    // Geodesic polyline for flight path
                    MapPolyline(coordinates: [depCoord, arrCoord])
                        .stroke(
                            LinearGradient(
                                colors: [PremiumTheme.electricBlue, PremiumTheme.goldStart],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 3
                        )
                    
                    // Departure marker
                    Annotation("", coordinate: depCoord) {
                        Circle()
                            .fill(PremiumTheme.electricBlue)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 1.5)
                            )
                    }
                    
                    // Arrival marker
                    Annotation("", coordinate: arrCoord) {
                        Circle()
                            .fill(PremiumTheme.goldStart)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 1.5)
                            )
                    }
                }
            }
        }
        .mapStyle(currentMapStyle)
        .mapControlVisibility(.hidden)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                updateCameraToFitRoutes()
            }
        }
        .onChange(of: flights) { _, _ in
            print("🌍 Flights changed - updating camera")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 1.5)) {
                    updateCameraToFitRoutes()
                }
            }
        }
    }
    
    private func updateCameraToFitRoutes() {
        print("🌍 updateCameraToFitRoutes called - flights count: \(flights.count)")
        // Default: Center on Atlantic Ocean for "Space View"
        let defaultCenter = CLLocationCoordinate2D(latitude: 30.0, longitude: -30.0)
        let spaceViewDistance: Double = 20_000_000 // 20,000km for true space view
        
        guard !flights.isEmpty else {
            // Show default globe view when no flights
            withAnimation(.easeInOut(duration: 1.0)) {
                mapCameraPosition = .camera(
                    MapCamera(
                        centerCoordinate: defaultCenter,
                        distance: spaceViewDistance,
                        heading: 0,
                        pitch: 0 // Straight-on view of globe
                    )
                )
            }
            return
        }
        
        // Collect all coordinates
        var allCoords: [CLLocationCoordinate2D] = []
        for flight in flights {
            if let dep = flight.departureAirport.coordinate {
                allCoords.append(dep)
            }
            if let arr = flight.arrivalAirport.coordinate {
                allCoords.append(arr)
            }
        }
        
        guard !allCoords.isEmpty else {
            withAnimation(.easeInOut(duration: 1.0)) {
                mapCameraPosition = .camera(
                    MapCamera(
                        centerCoordinate: defaultCenter,
                        distance: spaceViewDistance,
                        heading: 0,
                        pitch: 0
                    )
                )
            }
            return
        }
        
        // Calculate center of all routes
        let avgLat = allCoords.map { $0.latitude }.reduce(0, +) / Double(allCoords.count)
        let avgLon = allCoords.map { $0.longitude }.reduce(0, +) / Double(allCoords.count)
        
        // Offset the center South by ~10° to position routes in visible area above sheet
        let offsetLat = avgLat - 10.0
        let center = CLLocationCoordinate2D(latitude: offsetLat, longitude: avgLon)
        
        // Calculate span to fit all points
        let latitudes = allCoords.map { $0.latitude }
        let longitudes = allCoords.map { $0.longitude }
        let latSpan = (latitudes.max()! - latitudes.min()!) * 2.5
        let lonSpan = (longitudes.max()! - longitudes.min()!) * 2.5
        
        // Set camera - zoom in closer for route visibility (min 3,000km instead of 15,000km)
        let calculatedDistance = max(latSpan, lonSpan) * 111_000 * 2.5
        let distance = max(calculatedDistance, 3_000_000) // 3,000km minimum for route focus
        
        withAnimation(.easeInOut(duration: 1.0)) {
            mapCameraPosition = .camera(
                MapCamera(
                    centerCoordinate: center,
                    distance: distance,
                    heading: 0,
                    pitch: 25 // Slightly more tilt for better depth perception
                )
            )
        }
    }
}

#Preview {
    FlightsGlobeView(flights: [], isSatelliteView: .constant(true))
        .frame(height: 300)
}
