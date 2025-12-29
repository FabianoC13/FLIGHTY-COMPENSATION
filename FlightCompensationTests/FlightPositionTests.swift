import XCTest
@testable import FlightCompensation

final class FlightPositionTests: XCTestCase {
    func testMockPositionStreamProvidesPositionsAndMeta() async throws {
        let svc = MockFlightTrackingService()

        // Construct a DELAY001 flight (mock expects codes to be in airline.code + flightNumber)
        let airline = Airline(code: "", name: "TestAir", id: UUID())
        let dep = Airport(id: UUID(), code: "MAD", name: "Madrid", city: "Madrid", country: "Spain", latitude: 40.4983, longitude: -3.5676)
        let arr = Airport(id: UUID(), code: "CDG", name: "CDG", city: "Paris", country: "France", latitude: 49.0097, longitude: 2.5479)
        let flight = Flight(flightNumber: "001", airline: airline, departureAirport: dep, arrivalAirport: arr, scheduledDeparture: Date(), scheduledArrival: Date().addingTimeInterval(2*3600))

        var positions: [FlightPosition] = []
        for await pos in svc.positionUpdates(flight) {
            positions.append(pos)
        }

        XCTAssertGreaterThan(positions.count, 1, "Expected more than 1 position update from mock service")
        XCTAssertNotEqual(positions.first?.coordinate.latitude, positions.last?.coordinate.latitude)
        // At least one position should include a computed speed or heading
        XCTAssertTrue(positions.contains(where: { $0.speed != nil || $0.heading != nil }))
    }
}
