import Foundation

enum Config {
    private static let placeholderAPIKey = "YOUR_KEY|YOUR_SECRET"
    
    // FlightRadar24 API Key
    // Format: {key-id}|{key-secret}
    static var flightRadar24APIKey: String {
        if let key = ProcessInfo.processInfo.environment["FLIGHT_RADAR24_API_KEY"], !key.isEmpty {
            return key
        }

        // Provide a safe placeholder so a real key is never committed by accident
        return placeholderAPIKey
    }
    
    // Use real API or mock data
    // Default to mock data to avoid network issues in development environments
    static var useRealFlightTracking: Bool {
        if let override = ProcessInfo.processInfo.environment["USE_REAL_FLIGHT_TRACKING"]?.lowercased() {
            return override == "1" || override == "true" || override == "yes"
        }
        
        return flightRadar24APIKey != placeholderAPIKey
    }
}
