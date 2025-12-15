import Foundation

final class MockFlightTrackingService: FlightTrackingService {
    
    func getFlightDetails(_ flight: Flight) async throws -> Flight? {
        // Return nil - mock service doesn't update flight details
        return nil
    }
    
    func trackFlight(_ flight: Flight) async throws -> FlightStatus {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Simulate realistic status updates based on flight time
        let now = Date()
        let timeUntilDeparture = flight.scheduledDeparture.timeIntervalSince(now)
        
        if timeUntilDeparture > 3600 { // More than 1 hour until departure
            // Randomly return delayed status 20% of the time for realism
            if Int.random(in: 1...10) <= 2 {
                return .delayed
            }
            return .scheduled
        } else if timeUntilDeparture > 0 { // Less than 1 hour, hasn't departed
            return .delayed // Often delayed when close to departure
        } else {
            // Past departure time
            let timeSinceDeparture = now.timeIntervalSince(flight.scheduledDeparture)
            if timeSinceDeparture > flight.scheduledArrival.timeIntervalSince(flight.scheduledDeparture) {
                return .arrived
            } else {
                return .departed
            }
        }
    }
    
    func getFlightStatus(_ flightNumber: String, date: Date) async throws -> FlightStatus {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Mock status based on flight number hash for consistency
        let hash = abs(flightNumber.hashValue)
        
        switch hash % 5 {
        case 0:
            return .onTime
        case 1:
            return .delayed
        case 2:
            return .cancelled
        case 3:
            return .departed
        default:
            return .arrived
        }
    }
}


