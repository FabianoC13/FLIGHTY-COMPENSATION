import Foundation

final class MockWalletImportService: WalletImportService {
    
    func importFlightFromWallet() async throws -> Flight? {
        // Simulate WalletKit integration delay
        try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
        
        // In real implementation, this would use WalletKit to read boarding passes
        // For now, return mock data simulating a common flight
        
        let mockAirline = Airline(
            code: "FR",
            name: "Ryanair",
            logoURL: nil
        )
        
        let mockDepartureAirport = Airport(
            code: "MAD",
            name: "Adolfo Suárez Madrid–Barajas Airport",
            city: "Madrid",
            country: "Spain"
        )
        
        let mockArrivalAirport = Airport(
            code: "CDG",
            name: "Charles de Gaulle Airport",
            city: "Paris",
            country: "France"
        )
        
        // Create a flight for tomorrow
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let scheduledDeparture = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: tomorrow) ?? tomorrow
        let scheduledArrival = calendar.date(bySettingHour: 16, minute: 45, second: 0, of: tomorrow) ?? tomorrow
        
        let mockFlight = Flight(
            flightNumber: "1234",
            airline: mockAirline,
            departureAirport: mockDepartureAirport,
            arrivalAirport: mockArrivalAirport,
            scheduledDeparture: scheduledDeparture,
            scheduledArrival: scheduledArrival,
            status: .scheduled,
            currentStatus: .scheduled
        )
        
        return mockFlight
    }
}


