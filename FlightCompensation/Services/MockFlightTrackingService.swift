import Foundation
import CoreLocation

final class MockFlightTrackingService: FlightTrackingService {
    private let predefinedStatuses: [String: FlightStatus] = [
        "BA101": .delayed,
        "LH202": .delayed,
        "FR303": .delayed,
        "VY404": .onTime,
        "KL505": .onTime,
        "DL606": .delayed,
        "EK707": .delayed,
        "SQ808": .delayed,
        "UA909": .delayed,
        "AA1001": .delayed
    ]
    
    func getFlightDetails(_ flight: Flight) async throws -> Flight? {
        // If the flight code is one of our test codes, return a mock detailed flight
        let flightCode = "\(flight.airline.code)\(flight.flightNumber)".uppercased()
        if flightCode == "DELAY001" || flightCode == "DELAY002" || flightCode == "CANCEL001" {
            // Create deterministic airports and times
            let depAirport = Airport(
                id: UUID(uuidString: "12345678-1234-1234-1234-123456789001") ?? UUID(),
                code: "MAD",
                name: "Adolfo Suárez Madrid–Barajas Airport",
                city: "Madrid",
                country: "Spain",
                latitude: 40.4983,
                longitude: -3.5676
            )
            let arrAirport = Airport(
                id: UUID(uuidString: "12345678-1234-1234-1234-123456789002") ?? UUID(),
                code: "CDG",
                name: "Charles de Gaulle Airport",
                city: "Paris",
                country: "France",
                latitude: 49.0097,
                longitude: 2.5479
            )
            let scheduledDeparture = flight.scheduledDeparture
            let scheduledArrival = flight.scheduledArrival.timeIntervalSince(flight.scheduledDeparture) > 0
                ? flight.scheduledArrival
                : Calendar.current.date(byAdding: .hour, value: 2, to: scheduledDeparture) ?? scheduledDeparture

            var status: FlightStatus = .scheduled
            var currentStatus: FlightStatus = .scheduled
            var delayEvents: [DelayEvent] = []

            if flightCode == "DELAY001" {
                status = .delayed
                currentStatus = .delayed
                delayEvents = [DelayEvent(type: .delay, duration: 4 * 3600, actualTime: Calendar.current.date(byAdding: .hour, value: 4, to: scheduledArrival), reason: "Operational delay")]
            } else if flightCode == "DELAY002" {
                status = .delayed
                currentStatus = .delayed
                delayEvents = [DelayEvent(type: .delay, duration: 3.5 * 3600, actualTime: Calendar.current.date(byAdding: .hour, value: 3, to: scheduledArrival), reason: "Weather delay")]
            } else if flightCode == "CANCEL001" {
                status = .cancelled
                currentStatus = .cancelled
                delayEvents = [DelayEvent(type: .cancellation, duration: 0, actualTime: nil, reason: "Flight cancelled by airline")]
            }

            return Flight(
                id: flight.id,
                flightNumber: flight.flightNumber,
                airline: flight.airline,
                departureAirport: depAirport,
                arrivalAirport: arrAirport,
                scheduledDeparture: scheduledDeparture,
                scheduledArrival: scheduledArrival,
                status: status,
                currentStatus: currentStatus,
                delayEvents: delayEvents
            )
        }

        // Default: mock service doesn't update flight details
        return nil
    }
    
    func trackFlight(_ flight: Flight) async throws -> FlightStatus {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let flightCode = "\(flight.airline.code)\(flight.flightNumber)".uppercased()
        // Force deterministic behavior for test codes
        if flightCode == "DELAY001" || flightCode == "DELAY002" {
            return .delayed
        }
        if flightCode == "CANCEL001" {
            return .cancelled
        }

        if let status = predefinedStatuses[flightCode] {
            return status
        }
        
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
        
        let code = flightNumber.uppercased()
        if code == "DELAY001" || code == "DELAY002" {
            return .delayed
        }
        if code == "CANCEL001" {
            return .cancelled
        }

        if let status = predefinedStatuses[flightNumber] {
            return status
        }
        
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

    func positionUpdates(_ flight: Flight) -> AsyncStream<FlightPosition> {
        let flightCode = "\(flight.airline.code)\(flight.flightNumber)".uppercased()

        if flightCode == "DELAY001" || flightCode == "DELAY002" || flightCode == "CANCEL001" {
            // Determine origin/destination (fall back to MAD/CDG)
            let originCoord = flight.departureAirport.coordinate ?? CLLocationCoordinate2D(latitude: 40.4983, longitude: -3.5676)
            let destCoord = flight.arrivalAirport.coordinate ?? CLLocationCoordinate2D(latitude: 49.0097, longitude: 2.5479)

            func haversineDistanceMeters(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
                let R = 6371000.0
                let φ1 = a.latitude * .pi / 180
                let φ2 = b.latitude * .pi / 180
                let Δφ = (b.latitude - a.latitude) * .pi / 180
                let Δλ = (b.longitude - a.longitude) * .pi / 180
                let sa = sin(Δφ/2) * sin(Δφ/2) + cos(φ1) * cos(φ2) * sin(Δλ/2) * sin(Δλ/2)
                let c = 2 * atan2(sqrt(sa), sqrt(1-sa))
                return R * c
            }

            func bearingDegrees(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
                let φ1 = a.latitude * .pi / 180
                let φ2 = b.latitude * .pi / 180
                let λ1 = a.longitude * .pi / 180
                let λ2 = b.longitude * .pi / 180
                let y = sin(λ2-λ1) * cos(φ2)
                let x = cos(φ1)*sin(φ2) - sin(φ1)*cos(φ2)*cos(λ2-λ1)
                let θ = atan2(y, x)
                var deg = θ * 180 / .pi
                if deg < 0 { deg += 360 }
                return deg
            }

            return AsyncStream { continuation in
                Task {
                    let steps = 240
                    let intervalSeconds = 0.05
                    var lastCoord = originCoord
                    var lastTimestamp = Date()

                    // Simulate cruising altitude (meters) and descent
                    let originAlt = 11000.0 // meters
                    let destAlt = 200.0

                    for i in 0...steps {
                        let t = Double(i) / Double(steps)
                        let lat = originCoord.latitude + (destCoord.latitude - originCoord.latitude) * t
                        let lon = originCoord.longitude + (destCoord.longitude - originCoord.longitude) * t
                        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        let now = Date()

                        // compute heading from previous point (or towards destination for first step)
                        let heading = i == 0 ? bearingDegrees(from: coord, to: destCoord) : bearingDegrees(from: lastCoord, to: coord)

                        // Return realistic cruising speed (approx 860 km/h) instead of simulation speed
                        let speed: Double? = 240.0

                        // interpolate altitude
                        let altitude = originAlt + (destAlt - originAlt) * t

                        let pos = FlightPosition(latitude: coord.latitude, longitude: coord.longitude, altitude: altitude, heading: heading, speed: speed, timestamp: now)
                        continuation.yield(pos)

                        lastCoord = coord
                        lastTimestamp = now

                        try await Task.sleep(nanoseconds: UInt64(intervalSeconds * 1_000_000_000))
                    }

                    continuation.finish()
                }
            }
        }

        // Default: no live positions available
        return AsyncStream { continuation in continuation.finish() }
    }
}
