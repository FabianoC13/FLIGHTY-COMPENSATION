import Foundation

struct Flight: Codable, Equatable, Hashable, Identifiable {
    let id: UUID
    let flightNumber: String
    let airline: Airline
    let departureAirport: Airport
    let arrivalAirport: Airport
    let scheduledDeparture: Date
    let scheduledArrival: Date
    let status: FlightStatus
    var currentStatus: FlightStatus
    var delayEvents: [DelayEvent]
    
    init(
        id: UUID = UUID(),
        flightNumber: String,
        airline: Airline,
        departureAirport: Airport,
        arrivalAirport: Airport,
        scheduledDeparture: Date,
        scheduledArrival: Date,
        status: FlightStatus = .scheduled,
        currentStatus: FlightStatus = .scheduled,
        delayEvents: [DelayEvent] = []
    ) {
        self.id = id
        self.flightNumber = flightNumber
        self.airline = airline
        self.departureAirport = departureAirport
        self.arrivalAirport = arrivalAirport
        self.scheduledDeparture = scheduledDeparture
        self.scheduledArrival = scheduledArrival
        self.status = status
        self.currentStatus = currentStatus
        self.delayEvents = delayEvents
    }
    
    var route: String {
        "\(departureAirport.code) → \(arrivalAirport.code)"
    }
    
    var displayFlightNumber: String {
        "\(airline.code)\(flightNumber)"
    }
    
    var hasActiveDelay: Bool {
        currentStatus == .delayed || currentStatus == .cancelled
    }
    
    var latestDelayEvent: DelayEvent? {
        delayEvents.last
    }
}


