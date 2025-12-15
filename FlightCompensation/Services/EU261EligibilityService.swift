import Foundation
import CoreLocation

final class EU261EligibilityService: EligibilityService {
    
    func checkEligibility(for flight: Flight, delayEvent: DelayEvent) async -> CompensationEligibility {
        // 1. Check jurisdiction (EU/UK airline or route)
        guard isWithinJurisdiction(flight: flight) else {
            return CompensationEligibility(
                isEligible: false,
                amount: 0,
                reason: "EU261 rules apply to flights operated by EU/UK airlines or departing from EU/UK airports.",
                confidence: 1.0
            )
        }
        
        // 2. Check if cancelled
        if delayEvent.type == .cancellation {
            return handleCancellation(flight: flight, delayEvent: delayEvent)
        }
        
        // 3. Check delay duration (must be 3+ hours arrival delay)
        guard delayEvent.durationInHours >= 3.0 else {
            return CompensationEligibility(
                isEligible: false,
                amount: 0,
                reason: "Arrival delay must be at least 3 hours to be eligible for compensation.",
                confidence: 1.0
            )
        }
        
        // 4. Calculate distance
        let distance = calculateDistance(
            from: flight.departureAirport,
            to: flight.arrivalAirport
        )
        
        // 5. Apply EU261 rules
        return determineCompensation(distance: distance, delayHours: delayEvent.durationInHours)
    }
    
    private func isWithinJurisdiction(flight: Flight) -> Bool {
        // Check if airline is EU/UK
        if flight.airline.isEUAirline {
            return true
        }
        
        // Check if departure is from EU/UK
        if isEUAirport(code: flight.departureAirport.code) {
            return true
        }
        
        return false
    }
    
    private func isEUAirport(code: String) -> Bool {
        // Major EU/UK airport codes (simplified - would be more comprehensive in production)
        let euAirports = [
            "LHR", "LGW", "STN", "LTN", "EDI", "GLA", "MAN", "BHX", // UK
            "CDG", "ORY", "LYS", "MRS", "NCE", "TLS", // France
            "AMS", "EIN", "RTM", // Netherlands
            "FRA", "MUC", "HAM", "BER", "DUS", "CGN", // Germany
            "MAD", "BCN", "AGP", "VLC", // Spain
            "FCO", "MXP", "LIN", "VCE", // Italy
            "LIS", "OPO", // Portugal
            "BRU", "ANR", // Belgium
            "VIE", // Austria
            "ZRH", "GVA", // Switzerland
            "CPH", "ARN", "OSL", // Scandinavia
            "ATH", "SKG", // Greece
            "DUB", "SNN" // Ireland
        ]
        return euAirports.contains(code)
    }
    
    private func calculateDistance(from: Airport, to: Airport) -> Double {
        // Simplified distance calculation using airport coordinates
        // In production, this would use actual airport coordinates database
        
        // Mock coordinates for major airports (would use a real database)
        let airportCoords: [String: (lat: Double, lon: Double)] = [
            "LHR": (51.4700, -0.4543),
            "CDG": (49.0097, 2.5479),
            "AMS": (52.3105, 4.7683),
            "FRA": (50.0379, 8.5622),
            "MAD": (40.4839, -3.5680),
            "MUC": (48.3538, 11.7861),
            "BCN": (41.2971, 2.0785),
            "JFK": (40.6413, -73.7781),
            "LAX": (33.9425, -118.4081),
            "DXB": (25.2532, 55.3657),
            "SIN": (1.3644, 103.9915),
            "NRT": (35.7647, 140.3863)
        ]
        
        guard let fromCoords = airportCoords[from.code],
              let toCoords = airportCoords[to.code] else {
            // Default to approximate calculation if airport not found
            return 1500.0 // Default to medium distance
        }
        
        // Haversine formula to calculate distance in kilometers
        let R = 6371.0 // Earth radius in km
        let lat1Rad = fromCoords.lat * .pi / 180
        let lat2Rad = toCoords.lat * .pi / 180
        let deltaLat = (toCoords.lat - fromCoords.lat) * .pi / 180
        let deltaLon = (toCoords.lon - fromCoords.lon) * .pi / 180
        
        let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLon / 2) * sin(deltaLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return R * c
    }
    
    private func determineCompensation(distance: Double, delayHours: Double) -> CompensationEligibility {
        // EU261 compensation rules:
        // ≤1500km: €250
        // >1500km intra-EU: €400
        // >3500km: €400 (3-4h delay) or €600 (4+h delay)
        
        if distance <= 1500 {
            return CompensationEligibility(
                isEligible: true,
                amount: 250,
                reason: "Your flight was delayed by \(Int(delayHours)) hours. Under EU261, you're entitled to €250 for flights up to 1,500km.",
                confidence: 0.95
            )
        } else if distance <= 3500 {
            // Check if intra-EU route (simplified - would check both airports)
            return CompensationEligibility(
                isEligible: true,
                amount: 400,
                reason: "Your flight was delayed by \(Int(delayHours)) hours. Under EU261, you're entitled to €400 for flights over 1,500km within the EU.",
                confidence: 0.95
            )
        } else {
            // Long-haul flights
            if delayHours >= 4 {
                return CompensationEligibility(
                    isEligible: true,
                    amount: 600,
                    reason: "Your flight was delayed by \(Int(delayHours)) hours. Under EU261, you're entitled to €600 for long-haul flights delayed by 4+ hours.",
                    confidence: 0.95
                )
            } else {
                return CompensationEligibility(
                    isEligible: true,
                    amount: 400,
                    reason: "Your flight was delayed by \(Int(delayHours)) hours. Under EU261, you're entitled to €400 for long-haul flights delayed by 3+ hours.",
                    confidence: 0.95
                )
            }
        }
    }
    
    private func handleCancellation(flight: Flight, delayEvent: DelayEvent) -> CompensationEligibility {
        let distance = calculateDistance(
            from: flight.departureAirport,
            to: flight.arrivalAirport
        )
        
        // For cancellations, similar rules apply but with some nuances
        // Simplified: treat similarly to delays
        if distance <= 1500 {
            return CompensationEligibility(
                isEligible: true,
                amount: 250,
                reason: "Your flight was cancelled. Under EU261, you're entitled to €250 for cancelled flights up to 1,500km.",
                confidence: 0.9
            )
        } else if distance <= 3500 {
            return CompensationEligibility(
                isEligible: true,
                amount: 400,
                reason: "Your flight was cancelled. Under EU261, you're entitled to €400 for cancelled flights over 1,500km.",
                confidence: 0.9
            )
        } else {
            return CompensationEligibility(
                isEligible: true,
                amount: 600,
                reason: "Your flight was cancelled. Under EU261, you're entitled to €600 for cancelled long-haul flights.",
                confidence: 0.9
            )
        }
    }
}


