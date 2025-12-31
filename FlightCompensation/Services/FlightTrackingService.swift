import Foundation
import CoreLocation

struct FlightPosition: Equatable {
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let heading: Double?
    let speed: Double? // meters per second
    let timestamp: Date

    var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
}

protocol FlightTrackingService {
    func trackFlight(_ flight: Flight) async throws -> FlightStatus
    func getFlightStatus(_ flightNumber: String, date: Date) async throws -> FlightStatus
    func getFlightDetails(_ flight: Flight) async throws -> Flight?

    /// Stream of position updates for the given flight. Implementations may return an empty/finished stream when live positions are not available.
    func positionUpdates(_ flight: Flight) -> AsyncStream<FlightPosition>
}


