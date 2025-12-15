import Foundation

final class FlightRadar24Service: FlightTrackingService {
    private let apiKey: String
    // Use sandbox endpoint for sandbox tokens
    private let baseURL = "https://api.flightradar24.com/common/v1"
    private let isSandbox: Bool
    
    init(apiKey: String) {
        self.apiKey = apiKey
        // Detect if it's a sandbox token (sandbox tokens often have specific patterns)
        self.isSandbox = apiKey.contains("sandbox") || apiKey.contains("019b1ebe")
    }
    
    func trackFlight(_ flight: Flight) async throws -> FlightStatus {
        let flightNumber = "\(flight.airline.code)\(flight.flightNumber)"
        return try await getFlightStatus(flightNumber, date: flight.scheduledDeparture)
    }
    
    func getFlightDetails(_ flight: Flight) async throws -> Flight? {
        let flightNumber = "\(flight.airline.code)\(flight.flightNumber)"
        return try await fetchFlightDetails(flightNumber: flightNumber, existingFlight: flight)
    }
    
    func getFlightStatus(_ flightNumber: String, date: Date) async throws -> FlightStatus {
        // Format: BA123, FR456, etc.
        // The API accepts the full flight code: airline code + flight number
        // Examples: "BA178", "FR1234", "LH441"
        let formattedFlightNumber = flightNumber.uppercased().trimmingCharacters(in: .whitespaces)
        
        // Testing: Force delay for specific flight codes
        if formattedFlightNumber == "DELAY001" || formattedFlightNumber == "DELAY002" {
            print("🧪 Testing mode: Forcing delay for \(formattedFlightNumber)")
            return .delayed
        }
        
        if formattedFlightNumber == "CANCEL001" {
            print("🧪 Testing mode: Forcing cancellation for \(formattedFlightNumber)")
            return .cancelled
        }
        
        // FlightRadar24 API endpoint for flight status
        // Try using /flight/list.json endpoint
        guard let url = URL(string: "\(baseURL)/flight/list.json") else {
            throw FlightRadar24Error.invalidURL
        }
        
        // Add query parameters
        // According to API error, we MUST use 'query' and 'fetchBy' parameters
        // query must be at least 3 characters long
        // fetchBy is required
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        // Validate flight number format (should be airline code + number, e.g., BA178, not just A320)
        guard formattedFlightNumber.count >= 3 else {
            throw FlightRadar24Error.invalidFlightNumber("Flight code must be at least 3 characters (e.g., BA178, FR1234)")
        }
        
        // Use 'query' and 'fetchBy' as required by API
        components?.queryItems = [
            URLQueryItem(name: "query", value: formattedFlightNumber),
            URLQueryItem(name: "fetchBy", value: "flight"),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "limit", value: "1")
        ]
        
        guard let finalURL = components?.url else {
            throw FlightRadar24Error.invalidURL
        }
        
        // Log request details
        print("🚀 FlightRadar24 API Request:")
        print("   Flight Number: \(formattedFlightNumber)")
        print("   URL: \(finalURL.absoluteString)")
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        
        // FlightRadar24 API key format: {key-id}|{key-secret} or {access-token}
        // For sandbox tokens, it's typically: {key-id}|{key-secret}
        if apiKey.contains("|") {
            let parts = apiKey.components(separatedBy: "|")
            if parts.count == 2 {
                // Try multiple authentication methods for sandbox
                // Method 1: Split into Id and Secret
                request.setValue(parts[0], forHTTPHeaderField: "X-API-Key-Id")
                request.setValue(parts[1], forHTTPHeaderField: "X-API-Key-Secret")
                // Also try as Authorization Bearer token
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                // And as Access-Token header (common for sandbox)
                request.setValue(apiKey, forHTTPHeaderField: "Access-Token")
                print("   Using split API key (Id + Secret) + Bearer + Access-Token")
            }
        } else {
            // Single token - try as Bearer token
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue(apiKey, forHTTPHeaderField: "Access-Token")
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
            print("   Using Bearer token + Access-Token + X-API-Key")
        }
        
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ FlightRadar24: Invalid response type")
                throw FlightRadar24Error.invalidResponse
            }
            
            // Log response for debugging
            print("📡 FlightRadar24 API Response:")
            print("   Status Code: \(httpResponse.statusCode)")
            print("   URL: \(httpResponse.url?.absoluteString ?? "unknown")")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
                print("❌ FlightRadar24 API Error Response:")
                print("   Status: \(httpResponse.statusCode)")
                print("   Body: \(responseString.prefix(500))")
                
                if httpResponse.statusCode == 401 {
                    print("   Error: Unauthorized - Check API key")
                    throw FlightRadar24Error.unauthorized
                } else if httpResponse.statusCode == 404 {
                    print("   Error: Flight not found")
                    throw FlightRadar24Error.flightNotFound
                } else {
                    print("   Error: Server error")
                    throw FlightRadar24Error.serverError(httpResponse.statusCode)
                }
            }
            
            // Log successful response - show more data for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("✅ FlightRadar24 API Success Response:")
                print("   Full response: \(responseString)")
            }
            
            // Try to parse response - be flexible with structure
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("📦 Parsed JSON response")
                
                // Extract and log all available data for debugging
                if let result = json["result"] as? [String: Any],
                   let response = result["response"] as? [String: Any],
                   let dataArray = response["data"] as? [[String: Any]],
                   let firstFlight = dataArray.first {
                    print("📊 Flight data available:")
                    print("   - Identification: \(firstFlight["identification"] ?? "none")")
                    print("   - Status: \(firstFlight["status"] ?? "none")")
                    print("   - Airport: \(firstFlight["airport"] ?? "none")")
                    print("   - Time: \(firstFlight["time"] ?? "none")")
                }
                
                // Try to extract status from various possible structures
                if let status = extractStatus(from: json) {
                    print("✅ Extracted status: \(status)")
                    return status
                } else {
                    print("⚠️ Could not extract status from JSON structure")
                }
            } else {
                print("⚠️ Could not parse JSON from response")
            }
            
            // Try structured decoding
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            if let apiResponse = try? decoder.decode(FlightRadar24Response.self, from: data) {
                print("✅ Decoded structured response")
                
                // Check if we have data in the response
                if let responseData = apiResponse.result?.response?.data, !responseData.isEmpty {
                    print("   Found \(responseData.count) flight(s) in response")
                    return try mapToFlightStatus(apiResponse)
                } else {
                    // Even if structured decode fails, try JSON extraction which should work
                    print("⚠️ Structured decode found data but couldn't extract status")
                    // extractStatus should have been called already, but if not, try again
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let status = extractStatus(from: json) {
                        print("✅ Extracted status from JSON: \(status)")
                        return status
                    }
                    print("   Returning scheduled status as fallback")
                    return .scheduled
                }
            } else {
                print("⚠️ Could not decode structured response")
            }
            
            // If we can't parse, return scheduled as fallback
            print("⚠️ Using fallback status: scheduled")
            return .scheduled
            
        } catch let error as FlightRadar24Error {
            print("❌ FlightRadar24 Error: \(error.localizedDescription)")
            throw error
        } catch {
            // For debugging: log the error
            print("❌ FlightRadar24 API Error: \(error.localizedDescription)")
            print("   Error type: \(type(of: error))")
            
            // If request failed with network error, try fallback approach with 'query' parameter
            if (error as NSError).domain == NSURLErrorDomain {
                print("   Network error detected, trying fallback method...")
                do {
                    return try await getFlightStatusFallback(formattedFlightNumber)
                } catch {
                    print("   Fallback also failed: \(error.localizedDescription)")
                    throw FlightRadar24Error.decodingError(error)
                }
            } else {
                throw FlightRadar24Error.decodingError(error)
            }
        }
    }
    
    // This method is no longer needed since we use query/fetchBy by default
    // Keeping it as fallback for other endpoints if needed
    private func getFlightStatusFallback(_ flightNumber: String) async throws -> FlightStatus {
        guard let url = URL(string: "\(baseURL)/flight/list.json") else {
            throw FlightRadar24Error.invalidURL
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "query", value: flightNumber),
            URLQueryItem(name: "fetchBy", value: "flight"),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "limit", value: "1")
        ]
        
        guard let finalURL = components?.url else {
            throw FlightRadar24Error.invalidURL
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        
        if apiKey.contains("|") {
            let parts = apiKey.components(separatedBy: "|")
            if parts.count == 2 {
                request.setValue(parts[0], forHTTPHeaderField: "X-API-Key-Id")
                request.setValue(parts[1], forHTTPHeaderField: "X-API-Key-Secret")
            }
        } else {
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        }
        
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FlightRadar24Error.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw FlightRadar24Error.unauthorized
            } else if httpResponse.statusCode == 404 {
                throw FlightRadar24Error.flightNotFound
            } else {
                throw FlightRadar24Error.serverError(httpResponse.statusCode)
            }
        }
        
        // Try to parse response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let status = extractStatus(from: json) {
                return status
            }
        }
        
        return .scheduled
    }
    
    private func extractStatus(from json: [String: Any]) -> FlightStatus? {
        // Try various JSON structures that FlightRadar24 might use
        // Based on actual API response: {"status":{"live":false,"text":"Scheduled"}}
        
        // Check common status fields
        func checkStatus(_ value: Any?) -> FlightStatus? {
            guard let statusString = value as? String else { return nil }
            let lowercased = statusString.lowercased().trimmingCharacters(in: .whitespaces)
            
            // Map FlightRadar24 status text to our FlightStatus enum
            if lowercased.contains("cancelled") || lowercased.contains("cancel") {
                return .cancelled
            } else if lowercased.contains("arrived") || lowercased.contains("arrival") {
                return .arrived
            } else if lowercased.contains("departed") || lowercased.contains("departure") || lowercased.contains("in flight") {
                return .departed
            } else if lowercased.contains("delayed") || lowercased.contains("delay") {
                return .delayed
            } else if lowercased.contains("ontime") || lowercased.contains("on time") || lowercased.contains("on-time") {
                return .onTime
            } else if lowercased.contains("scheduled") || lowercased.contains("landed") {
                return .scheduled
            }
            
            return nil
        }
        
        // Try the actual FlightRadar24 structure: result.response.data[].status.text
        if let result = json["result"] as? [String: Any],
           let response = result["response"] as? [String: Any],
           let data = response["data"] as? [[String: Any]],
           let firstFlight = data.first {
            
            // Try status.text with live flag (the actual structure we're seeing)
            if let status = firstFlight["status"] as? [String: Any] {
                let statusText = status["text"] as? String
                let live = status["live"] as? Bool
                
                print("   Status info - text: \(statusText ?? "nil"), live: \(live?.description ?? "nil")")
                
                // If live is true, flight is in the air regardless of text
                if live == true {
                    print("   ✅ Flight is live (in the air) - returning .departed")
                    return .departed
                }
                
                if let text = statusText {
                    if let flightStatus = checkStatus(text) {
                        return flightStatus
                    }
                }
            }
            
            // Try flightStatus.status.statusText (older structure)
            if let flightStatus = firstFlight["flightStatus"] as? [String: Any],
               let status = flightStatus["status"] as? [String: Any],
               let statusText = status["statusText"] as? String {
                print("   Extracted status from flightStatus.status.statusText: \(statusText)")
                return checkStatus(statusText)
            }
        }
        
        // Try simpler structure
        if let status = json["status"] as? [String: Any],
           let text = status["text"] as? String {
            return checkStatus(text)
        }
        
        if let status = json["status"] as? String {
            return checkStatus(status)
        }
        
        if let flightStatus = json["flightStatus"] as? [String: Any],
           let status = flightStatus["status"] as? String {
            return checkStatus(status)
        }
        
        return nil
    }
    
    private func mapToFlightStatus(_ response: FlightRadar24Response) throws -> FlightStatus {
        // Check if data exists and has flights
        guard let responseData = response.result?.response?.data,
              !responseData.isEmpty else {
            // If data is null or empty, the flight doesn't exist in the API right now
            print("⚠️ No flight data in API response - flight may be scheduled or completed")
            return .scheduled
        }
        
        // Try to get status from the first flight
        // The actual structure is: data[0].status.text
        if let firstFlight = responseData.first {
            // Try the actual structure: status.text with live flag
            if let statusInfo = firstFlight.status {
                // Check live flag first - if true, flight is in the air
                if statusInfo.live == true {
                    print("   ✅ Flight is LIVE (in the air) - returning .departed")
                    return .departed
                }
                
                if let statusText = statusInfo.text {
                    print("   ✅ Found status from status.text: \(statusText), live: \(statusInfo.live?.description ?? "nil")")
                    return mapStatusText(statusText, live: statusInfo.live)
                }
            }
            
            // Try using the structured models (old structure)
            if let flightStatus = firstFlight.flightStatus,
               let status = flightStatus.status,
               let statusText = status.statusText {
                print("   ✅ Found status from flightStatus.status.statusText: \(statusText)")
                return mapStatusText(statusText)
            }
        }
        
        // Fallback to scheduled
        print("   ⚠️ Could not extract status from structured response")
        return .scheduled
    }
    
    // Fetch complete flight details including airports and times
    private func fetchFlightDetails(flightNumber: String, existingFlight: Flight) async throws -> Flight? {
        let formattedFlightNumber = flightNumber.uppercased().trimmingCharacters(in: .whitespaces)
        
        guard let url = URL(string: "\(baseURL)/flight/list.json") else {
            throw FlightRadar24Error.invalidURL
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "query", value: formattedFlightNumber),
            URLQueryItem(name: "fetchBy", value: "flight"),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "limit", value: "1")
        ]
        
        guard let finalURL = components?.url else {
            throw FlightRadar24Error.invalidURL
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        
        if apiKey.contains("|") {
            let parts = apiKey.components(separatedBy: "|")
            if parts.count == 2 {
                request.setValue(parts[0], forHTTPHeaderField: "X-API-Key-Id")
                request.setValue(parts[1], forHTTPHeaderField: "X-API-Key-Secret")
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue(apiKey, forHTTPHeaderField: "Access-Token")
            }
        } else {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue(apiKey, forHTTPHeaderField: "Access-Token")
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        }
        
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return nil
        }
        
        // Try to parse JSON directly to extract airport data
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? [String: Any],
              let responseData = result["response"] as? [String: Any],
              let dataArray = responseData["data"] as? [[String: Any]],
              let firstFlight = dataArray.first else {
            print("⚠️ fetchFlightDetails: Could not parse flight data from response")
            return nil
        }
        
        print("🔍 fetchFlightDetails: Parsing flight data...")
        print("   Available keys in flight data: \(firstFlight.keys.joined(separator: ", "))")
        
        var updatedFlight = existingFlight
        
        // Extract airport information from JSON
        // Try multiple possible structures
        if let airportData = firstFlight["airport"] as? [String: Any] {
            print("📍 Found airport data in response")
            
            // Extract origin airport - try different structures
            var originIATA: String?
            var originName: String?
            var originCountry: String?
            
            if let origin = airportData["origin"] as? [String: Any] {
                // Try code.iata
                if let originCode = origin["code"] as? [String: Any] {
                    originIATA = originCode["iata"] as? String ?? originCode["icao"] as? String
                }
                // Try direct code string
                if originIATA == nil, let code = origin["code"] as? String {
                    originIATA = code
                }
                
                if let info = origin["info"] as? [String: Any] {
                    originName = info["name"] as? String
                    if let position = info["position"] as? [String: Any],
                       let country = position["country"] as? [String: Any] {
                        originCountry = country["name"] as? String
                    }
                }
                
                if let code = originIATA, !code.isEmpty {
                    updatedFlight = Flight(
                        id: existingFlight.id,
                        flightNumber: existingFlight.flightNumber,
                        airline: existingFlight.airline,
                        departureAirport: Airport(
                            id: existingFlight.departureAirport.id,
                            code: code,
                            name: originName ?? code,
                            city: code,
                            country: originCountry ?? ""
                        ),
                        arrivalAirport: existingFlight.arrivalAirport,
                        scheduledDeparture: existingFlight.scheduledDeparture,
                        scheduledArrival: existingFlight.scheduledArrival,
                        status: existingFlight.status,
                        currentStatus: existingFlight.currentStatus,
                        delayEvents: existingFlight.delayEvents
                    )
                    print("✅ Updated departure airport: \(code)")
                }
            }
            
            // Extract destination airport
            var destIATA: String?
            var destName: String?
            var destCountry: String?
            
            if let destination = airportData["destination"] as? [String: Any] {
                // Try code.iata
                if let destCode = destination["code"] as? [String: Any] {
                    destIATA = destCode["iata"] as? String ?? destCode["icao"] as? String
                }
                // Try direct code string
                if destIATA == nil, let code = destination["code"] as? String {
                    destIATA = code
                }
                
                if let info = destination["info"] as? [String: Any] {
                    destName = info["name"] as? String
                    if let position = info["position"] as? [String: Any],
                       let country = position["country"] as? [String: Any] {
                        destCountry = country["name"] as? String
                    }
                }
                
                if let code = destIATA, !code.isEmpty {
                    updatedFlight = Flight(
                        id: updatedFlight.id,
                        flightNumber: updatedFlight.flightNumber,
                        airline: updatedFlight.airline,
                        departureAirport: updatedFlight.departureAirport,
                        arrivalAirport: Airport(
                            id: existingFlight.arrivalAirport.id,
                            code: code,
                            name: destName ?? code,
                            city: code,
                            country: destCountry ?? ""
                        ),
                        scheduledDeparture: updatedFlight.scheduledDeparture,
                        scheduledArrival: updatedFlight.scheduledArrival,
                        status: updatedFlight.status,
                        currentStatus: updatedFlight.currentStatus,
                        delayEvents: updatedFlight.delayEvents
                    )
                    print("✅ Updated arrival airport: \(code)")
                }
            }
        } else {
            print("⚠️ No airport data found in response")
        }
        
        // Extract time information - try multiple structures
        if let timeData = firstFlight["time"] as? [String: Any] {
            print("⏰ Found time data in response")
            var finalFlight = updatedFlight
            
            // Try scheduled times
            if let scheduled = timeData["scheduled"] as? [String: Any] {
                if let depTimestamp = scheduled["departure"] as? Int {
                    let depDate = Date(timeIntervalSince1970: TimeInterval(depTimestamp))
                    finalFlight = Flight(
                        id: finalFlight.id,
                        flightNumber: finalFlight.flightNumber,
                        airline: finalFlight.airline,
                        departureAirport: finalFlight.departureAirport,
                        arrivalAirport: finalFlight.arrivalAirport,
                        scheduledDeparture: depDate,
                        scheduledArrival: finalFlight.scheduledArrival,
                        status: finalFlight.status,
                        currentStatus: finalFlight.currentStatus,
                        delayEvents: finalFlight.delayEvents
                    )
                    print("✅ Updated scheduled departure time: \(depDate)")
                }
                
                if let arrTimestamp = scheduled["arrival"] as? Int {
                    let arrDate = Date(timeIntervalSince1970: TimeInterval(arrTimestamp))
                    finalFlight = Flight(
                        id: finalFlight.id,
                        flightNumber: finalFlight.flightNumber,
                        airline: finalFlight.airline,
                        departureAirport: finalFlight.departureAirport,
                        arrivalAirport: finalFlight.arrivalAirport,
                        scheduledDeparture: finalFlight.scheduledDeparture,
                        scheduledArrival: arrDate,
                        status: finalFlight.status,
                        currentStatus: finalFlight.currentStatus,
                        delayEvents: finalFlight.delayEvents
                    )
                    print("✅ Updated scheduled arrival time: \(arrDate)")
                }
            }
            
            // Try real/actual times if available
            if let real = timeData["real"] as? [String: Any] {
                if let depTimestamp = real["departure"] as? Int {
                    print("   Found real departure time: \(Date(timeIntervalSince1970: TimeInterval(depTimestamp)))")
                }
                if let arrTimestamp = real["arrival"] as? Int {
                    print("   Found real arrival time: \(Date(timeIntervalSince1970: TimeInterval(arrTimestamp)))")
                }
            }
            
            return finalFlight
        } else {
            print("⚠️ No time data found in response")
        }
        
        return updatedFlight
    }
    
    private func mapStatusText(_ statusText: String, live: Bool? = nil) -> FlightStatus {
        // If live is true, flight is in the air regardless of text
        if live == true {
            return .departed
        }
        
        let lowercased = statusText.lowercased().trimmingCharacters(in: .whitespaces)
        
        if lowercased.contains("cancelled") || lowercased.contains("cancel") {
            return .cancelled
        } else if lowercased.contains("arrived") || lowercased.contains("arrival") || lowercased.contains("landed") {
            return .arrived
        } else if lowercased.contains("departed") || lowercased.contains("departure") || lowercased.contains("in flight") || lowercased.contains("en route") {
            return .departed
        } else if lowercased.contains("delayed") || lowercased.contains("delay") {
            return .delayed
        } else if lowercased.contains("ontime") || lowercased.contains("on time") || lowercased.contains("on-time") {
            return .onTime
        } else {
            return .scheduled
        }
    }
}

// MARK: - Error Types

enum FlightRadar24Error: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case flightNotFound
    case serverError(Int)
    case decodingError(Error)
    case invalidFlightNumber(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized. Please check your API key."
        case .flightNotFound:
            return "Flight not found"
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .invalidFlightNumber(let message):
            return message
        }
    }
}

// MARK: - API Response Models

struct FlightRadar24Response: Codable {
    let result: FlightRadar24Result?
}

struct FlightRadar24Result: Codable {
    let response: FlightRadar24FlightResponse?
}

struct FlightRadar24FlightResponse: Codable {
    let data: [FlightRadar24FlightData]?
}

struct FlightRadar24FlightData: Codable {
    let flightStatus: FlightRadar24FlightStatus?
    let status: FlightRadar24StatusInfo? // Actual structure: status.text
    let identification: FlightRadar24Identification?
    let airport: FlightRadar24AirportDetails?
    let time: FlightRadar24Time?
}

struct FlightRadar24AirportDetails: Codable {
    let origin: FlightRadar24Airport?
    let destination: FlightRadar24Airport?
}

struct FlightRadar24StatusInfo: Codable {
    let live: Bool?
    let text: String? // This is what we need: "Scheduled", "Delayed", etc.
}

struct FlightRadar24Identification: Codable {
    let id: String?
    let number: FlightRadar24Number?
}

struct FlightRadar24Number: Codable {
    let `default`: String?
    let alternative: String?
}

struct FlightRadar24Airport: Codable {
    let code: FlightRadar24AirportCode?
    let info: FlightRadar24AirportInfo?
}

struct FlightRadar24AirportCode: Codable {
    let iata: String?
    let icao: String?
}

struct FlightRadar24AirportInfo: Codable {
    let name: String?
    let position: FlightRadar24Position?
}

struct FlightRadar24Position: Codable {
    let latitude: Double?
    let longitude: Double?
    let country: FlightRadar24Country?
}

struct FlightRadar24Country: Codable {
    let name: String?
    let code: String?
}

struct FlightRadar24Time: Codable {
    let scheduled: FlightRadar24TimeDetails?
    let estimated: FlightRadar24TimeDetails?
    let actual: FlightRadar24TimeDetails?
}

struct FlightRadar24TimeDetails: Codable {
    let departure: Int? // Unix timestamp
    let arrival: Int? // Unix timestamp
}

struct FlightRadar24FlightStatus: Codable {
    let status: FlightRadar24Status?
    let generic: FlightRadar24GenericStatus?
}

struct FlightRadar24Status: Codable {
    let statusText: String?
    let icon: String?
}

struct FlightRadar24GenericStatus: Codable {
    let status: FlightRadar24GenericStatusDetails?
}

struct FlightRadar24GenericStatusDetails: Codable {
    let text: String?
}

