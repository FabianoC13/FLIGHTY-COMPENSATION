import SwiftUI
import MapKit
import CoreLocation

struct FlightMapView: View {
    let originCoordinate: CLLocationCoordinate2D
    let destinationCoordinate: CLLocationCoordinate2D
    var planePosition: FlightPosition? = nil
    
    @State private var position: MapCameraPosition = .automatic
    @State private var route: MKPolyline?
    
    var body: some View {
        Map(position: $position) {
            // Origin
            Annotation("Origin", coordinate: originCoordinate) {
                Image(systemName: "airplane.departure")
                    .padding(6)
                    .background(Circle().fill(.ultraThinMaterial))
                    .foregroundStyle(.blue)
            }
            .annotationTitles(.hidden)
            
            // Destination
            Annotation("Destination", coordinate: destinationCoordinate) {
                Image(systemName: "airplane.arrival")
                    .padding(6)
                    .background(Circle().fill(.ultraThinMaterial))
                    .foregroundStyle(.green)
            }
            .annotationTitles(.hidden)
            
            // Live Plane
            if let plane = planePosition {
                Annotation("Flight", coordinate: plane.coordinate) {
                    Image(systemName: "airplane")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Circle().fill(Color.accentColor))
                        .shadow(radius: 4)
                        .rotationEffect(.degrees(plane.heading ?? 0))
                }
                .annotationTitles(.hidden)
            }
            
            // Geodesic Line
            if let route {
                MapPolyline(route)
                    .stroke(Color.accentColor.opacity(0.8), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [8, 6]))
            }
        }
        .mapStyle(.hybrid(elevation: .realistic))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onAppear {
            calculateGeodesicRoute()
        }
    }
    
    private func calculateGeodesicRoute() {
        let coords = [originCoordinate, destinationCoordinate]
        let geodesic = MKGeodesicPolyline(coordinates: coords, count: 2)
        self.route = geodesic
        
        // Initial fit (rough)
        // Map automatic usually handles annotations well, but we can force a look if needed.
    }
}

#Preview {
    FlightMapView(
        originCoordinate: CLLocationCoordinate2D(latitude: 51.47, longitude: -0.45),
        destinationCoordinate: CLLocationCoordinate2D(latitude: 40.64, longitude: -73.78),
        planePosition: FlightPosition(latitude: 50.0, longitude: -30.0, altitude: 10000, heading: 260, speed: 800, timestamp: Date())
    )
    .frame(height: 300)
    .preferredColorScheme(.dark)
}
