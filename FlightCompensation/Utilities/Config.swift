import Foundation

enum Config {
    // ⚠️ REPLACE THIS WITH YOUR REAL API KEY ⚠️
    // You can get one at https://flightradar24.com/premium
    // Format: "key_id|key_secret" OR "your_access_token"
    private static let placeholderAPIKey = "YOUR_REAL_API_KEY_HERE"
    
    // FlightRadar24 API Key
    static var flightRadar24APIKey: String {
        // 1. Check Environment Variables (Best for CI/CD)
        if let key = ProcessInfo.processInfo.environment["FLIGHT_RADAR24_API_KEY"], !key.isEmpty {
            return key
        }
        
        // 2. Fallback to the hardcoded key above (Easier for local dev)
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




