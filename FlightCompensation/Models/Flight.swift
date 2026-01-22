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
    
    // Claim tracking
    var claimStatus: ClaimStatus
    var claimReference: String?
    
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
        delayEvents: [DelayEvent] = [],
        claimStatus: ClaimStatus = .notStarted,
        claimReference: String? = nil
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
        self.claimStatus = claimStatus
        self.claimReference = claimReference
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

enum ClaimStatus: String, Codable, CaseIterable {
    case notStarted = "Not Started"
    case airlineClaimSubmitted = "Airline Contacted"
    case airlineRejected = "Airline Appeal"
    case aesaSubmitted = "AESA Submitted"
    case approved = "Approved"
    case paid = "Paid"
    
    var colorHex: String {
        switch self {
        case .notStarted: return "#808080" // Gray
        case .airlineClaimSubmitted: return "#3498DB" // Blue
        case .airlineRejected: return "#E74C3C" // Red (Action Needed)
        case .aesaSubmitted: return "#9B59B6" // Purple (Official)
        case .approved: return "#2ECC71" // Green
        case .paid: return "#FFD700" // Gold
        }
    }
}


