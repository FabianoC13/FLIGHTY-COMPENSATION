import Foundation

protocol FlightTrackingService {
    func trackFlight(_ flight: Flight) async throws -> FlightStatus
    func getFlightStatus(_ flightNumber: String, date: Date) async throws -> FlightStatus
    func getFlightDetails(_ flight: Flight) async throws -> Flight?
}


