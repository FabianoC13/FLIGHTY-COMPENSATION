import Foundation
import Combine

@MainActor
final class FlightsListViewModel: ObservableObject {
    @Published var flights: [Flight] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let flightTrackingService: FlightTrackingService
    private var cancellables = Set<AnyCancellable>()
    
    init(flightTrackingService: FlightTrackingService) {
        self.flightTrackingService = flightTrackingService
    }
    
    func loadFlights() {
        isLoading = true
        errorMessage = nil
        
        // In a real app, this would load from persistence/storage
        // For now, start with empty array
        Task {
            // Simulate loading
            try? await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    func addFlight(_ flight: Flight) {
        flights.append(flight)
        startTracking(flight)
    }
    
    func deleteFlight(_ flight: Flight) {
        flights.removeAll { $0.id == flight.id }
    }
    
    func refreshFlightStatus(_ flight: Flight) {
        startTracking(flight)
    }
    
    private func startTracking(_ flight: Flight) {
        Task {
            do {
                // First, get complete flight details (airports, times, etc.)
                var updatedFlight = flight
                if let flightWithDetails = try? await flightTrackingService.getFlightDetails(flight) {
                    updatedFlight = flightWithDetails
                    print("✅ Updated flight in list with API data (airports, times)")
                } else {
                    print("⚠️ Could not fetch flight details for list, using existing flight data")
                }
                
                // Then get the current status
                let status = try await flightTrackingService.trackFlight(updatedFlight)
                updatedFlight.currentStatus = status
                
                // Update flight in the list with all new data
                if let index = flights.firstIndex(where: { $0.id == flight.id }) {
                    flights[index] = updatedFlight
                    print("✅ Updated flight in list: \(updatedFlight.displayFlightNumber) - \(updatedFlight.route)")
                }
            } catch let error as FlightRadar24Error {
                errorMessage = error.localizedDescription
            } catch {
                errorMessage = "Unable to check flight status: \(error.localizedDescription)"
            }
        }
    }
}

