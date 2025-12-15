import Foundation

enum Config {
    // FlightRadar24 API Key
    // Format: {key-id}|{key-secret}
    static var flightRadar24APIKey: String {
        if let key = ProcessInfo.processInfo.environment["FLIGHT_RADAR24_API_KEY"], !key.isEmpty {
            return key
        }

        // Provide a safe placeholder so a real key is never committed by accident
        return "YOUR_KEY|YOUR_SECRET"
    }
    
    // Use real API or mock data
    // Default to mock data to avoid network issues in development environments
    static let useRealFlightTracking = false
}

