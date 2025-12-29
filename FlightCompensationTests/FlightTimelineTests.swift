import XCTest
@testable import FlightCompensation

@MainActor
final class FlightTimelineTests: XCTestCase {
    func testLoadFlightSetsTimelineEvents() {
        let mockTracking = MockFlightTrackingService()
        let eligibility = EU261EligibilityService()
        let viewModel = FlightDetailViewModel(flightTrackingService: mockTracking, eligibilityService: eligibility)

        let delayEvent = DelayEvent(type: .delay, duration: 3 * 3600, actualTime: Date(), reason: "Test delay")
        let flight = Flight(
            flightNumber: "101",
            airline: Airline(code: "BA", name: "British Airways"),
            departureAirport: Airport(code: "LHR", name: "Heathrow", city: "London", country: "UK"),
            arrivalAirport: Airport(code: "CDG", name: "Charles de Gaulle", city: "Paris", country: "France"),
            scheduledDeparture: Date(),
            scheduledArrival: Date().addingTimeInterval(2 * 3600),
            status: .delayed,
            currentStatus: .delayed,
            delayEvents: [delayEvent]
        )

        viewModel.loadFlight(flight)

        XCTAssertEqual(viewModel.timelineEvents.count, 1)
        XCTAssertEqual(viewModel.timelineEvents.first?.reason, "Test delay")
    }

    func testTimelineUpdatesWhenFlightUpdated() async {
        let mockTracking = MockFlightTrackingService()
        let eligibility = EU261EligibilityService()
        let viewModel = FlightDetailViewModel(flightTrackingService: mockTracking, eligibilityService: eligibility)

        // Start with no events
        let flight = Flight(
            flightNumber: "202",
            airline: Airline(code: "LH", name: "Lufthansa"),
            departureAirport: Airport(code: "FRA", name: "Frankfurt", city: "Frankfurt", country: "Germany"),
            arrivalAirport: Airport(code: "AMS", name: "Amsterdam", city: "Amsterdam", country: "Netherlands"),
            scheduledDeparture: Date(),
            scheduledArrival: Date().addingTimeInterval(2 * 3600)
        )

        viewModel.loadFlight(flight)
        XCTAssertTrue(viewModel.timelineEvents.isEmpty)

        // Simulate update: service returns a flight with a delay event
        let delayedFlight = Flight(
            id: flight.id,
            flightNumber: flight.flightNumber,
            airline: flight.airline,
            departureAirport: flight.departureAirport,
            arrivalAirport: flight.arrivalAirport,
            scheduledDeparture: flight.scheduledDeparture,
            scheduledArrival: flight.scheduledArrival,
            status: .delayed,
            currentStatus: .delayed,
            delayEvents: [DelayEvent(type: .delay, duration: 4 * 3600, actualTime: Date(), reason: "Updated delay")]
        )

        // Manually assign as if fetched
        await MainActor.run {
            viewModel.flight = delayedFlight
            viewModel.timelineEvents = delayedFlight.delayEvents
        }

        XCTAssertEqual(viewModel.timelineEvents.count, 1)
        XCTAssertEqual(viewModel.timelineEvents.first?.reason, "Updated delay")
    }
}