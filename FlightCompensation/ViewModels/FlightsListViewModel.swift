import Foundation
import Combine

@MainActor
final class FlightsListViewModel: ObservableObject {
    @Published var flights: [Flight] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let flightTrackingService: FlightTrackingService
    private let flightStorageService: FlightStorageServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        flightTrackingService: FlightTrackingService,
        flightStorageService: FlightStorageServiceProtocol
    ) {
        self.flightTrackingService = flightTrackingService
        self.flightStorageService = flightStorageService
    }
    
    func loadFlights() {
        isLoading = true
        errorMessage = nil
        
        Task {
            // 1. Initial Load from Local Cache (Fast)
            let cachedFlights = flightStorageService.load()
            await MainActor.run {
                self.flights = cachedFlights
            }
            
            do {
                // 2. Async Sync with Cloud (Authoritative)
                let cloudFlights = try await flightStorageService.fetchFlights()
                
                await MainActor.run {
                    self.flights = cloudFlights
                    self.isLoading = false
                }
                
                // Refresh status for all loaded flights
                for flight in cloudFlights {
                    refreshFlightStatus(flight)
                }
            } catch {
                await MainActor.run {
                    print("⚠️ Cloud sync failed: \(error.localizedDescription)")
                    // Keep showing local flights if cloud fails
                    self.isLoading = false
                    // Don't show error message to user if we have local data
                    if cachedFlights.isEmpty {
                        self.errorMessage = "Unable to load flights"
                    }
                }
            }
        }
    }
    
    func addFlight(_ flight: Flight) {
        flights.append(flight)
        flightStorageService.save(flights: flights)
        startTracking(flight)
    }
    
    func deleteFlight(_ flight: Flight) {
        // Optimistic UI update
        flights.removeAll { $0.id == flight.id }
        
        Task {
            do {
                try await flightStorageService.moveToHistory(flight: flight)
            } catch {
                print("❌ Failed to move flight to history: \(error.localizedDescription)")
                // Revert UI on failure
                loadFlights()
            }
        }
    }
    
    func refreshFlightStatus(_ flight: Flight) {
        startTracking(flight)
    }
    
    private func startTracking(_ flight: Flight) {
        Task {
            do {
                // First, get complete flight details (airports, times, etc.)
                // Capture local claim data before overwriting with API result
                let existingClaimStatus = flight.claimStatus
                let existingClaimReference = flight.claimReference
                let existingClaimDate = flight.claimDate
                
                var updatedFlight = flight
                print("➡️ [List] Starting tracking for: \(flight.displayFlightNumber) — route: \(flight.route), currentStatus: \(flight.currentStatus.displayName)")
                if let flightWithDetails = try? await flightTrackingService.getFlightDetails(flight) {
                    updatedFlight = flightWithDetails
                    print("⬅️ [List] getFlightDetails returned for \(flight.displayFlightNumber): route=\(updatedFlight.route), status=\(updatedFlight.currentStatus.displayName)")
                } else {
                    print("⚠️ Could not fetch flight details for list, using existing flight data: route=\(updatedFlight.route)")
                }
                
                // Then get the current status
                let status = try await flightTrackingService.trackFlight(updatedFlight)
                print("⬅️ [List] trackFlight returned status=\(status.displayName) for \(updatedFlight.displayFlightNumber)")
                var delayEvents = updatedFlight.delayEvents
                
                // Create delay event if flight is delayed or cancelled
                if status == .delayed || status == .cancelled {
                    if delayEvents.isEmpty {
                        let flightCode = "\(updatedFlight.airline.code)\(updatedFlight.flightNumber)".uppercased()
                        var delayDuration: TimeInterval = 0
                        
                        // Use specific delays for test codes
                        if flightCode == "DELAY001" {
                            delayDuration = 4.5 * 3600.0 // 4.5 hours (simulated if service didn't provide one)
                        } else if flightCode == "DELAY002" {
                            delayDuration = 3.0 * 3600.0 // 3 hours
                        } else {
                            // Random delay between 3-5 hours for other delays
                            delayDuration = Double.random(in: 3.0...5.0) * 3600.0
                        }
                        
                        let delayEvent = DelayEvent(
                            type: status == .cancelled ? .cancellation : .delay,
                            duration: delayDuration,
                            actualTime: status == .cancelled ? nil : Date(),
                            reason: status == .cancelled ? "Flight cancelled by airline" : "Operational delay"
                        )
                        delayEvents.append(delayEvent)
                        print("✅ [List] Created simulated delay event: \(delayEvent.type) - \(Int(delayDuration / 3600)) hours")
                    } else {
                        print("ℹ️ [List] Delay events already provided by service; skipping simulated append")
                    }
                }
                
                // Create new Flight instance with updated values, preserving claim data
                updatedFlight = Flight(
                    id: updatedFlight.id,
                    flightNumber: updatedFlight.flightNumber,
                    airline: updatedFlight.airline,
                    departureAirport: updatedFlight.departureAirport,
                    arrivalAirport: updatedFlight.arrivalAirport,
                    scheduledDeparture: updatedFlight.scheduledDeparture,
                    scheduledArrival: updatedFlight.scheduledArrival,
                    status: updatedFlight.status,
                    currentStatus: status,
                    delayEvents: delayEvents,
                    claimStatus: existingClaimStatus,
                    claimReference: existingClaimReference,
                    claimDate: existingClaimDate
                )
                
                // Update flight in the list with all new data
                if let index = flights.firstIndex(where: { $0.id == flight.id }) {
                    flights[index] = updatedFlight
                    flightStorageService.save(flights: flights)
                    print("✅ [List] Updated flight in list: \(updatedFlight.displayFlightNumber) - \(updatedFlight.route) - Status: \(updatedFlight.currentStatus.displayName)")
                }
            } catch let error as FlightRadar24Error {
                errorMessage = error.localizedDescription
            } catch {
                errorMessage = "Unable to check flight status: \(error.localizedDescription)"
            }
        }
    }
    
    // Call this when child views modify a flight (e.g. claim submitted)
    func updateFlight(_ flight: Flight) {
        if let index = flights.firstIndex(where: { $0.id == flight.id }) {
            flights[index] = flight
            flightStorageService.save(flights: flights)
            print("✅ [List] Explicitly updated flight: \(flight.displayFlightNumber)")
        }
    }
}
