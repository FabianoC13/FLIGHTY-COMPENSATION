import Foundation
import Combine

@MainActor
final class FlightDetailViewModel: ObservableObject {
    @Published var flight: Flight?
    @Published var eligibility: CompensationEligibility?
    @Published var isLoading: Bool = false
    @Published var isCheckingEligibility: Bool = false
    @Published var errorMessage: String?
    
    private let flightTrackingService: FlightTrackingService
    private let eligibilityService: EligibilityService
    private var cancellables = Set<AnyCancellable>()
    
    init(
        flight: Flight? = nil,
        flightTrackingService: FlightTrackingService,
        eligibilityService: EligibilityService
    ) {
        self.flight = flight
        self.flightTrackingService = flightTrackingService
        self.eligibilityService = eligibilityService
    }
    
    func loadFlight(_ flight: Flight) {
        self.flight = flight
        trackFlight()
        // Check eligibility after tracking completes (handled in trackFlight)
    }
    
    func trackFlight() {
        guard var flight = flight else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // First, get complete flight details (airports, times, etc.)
                if let updatedFlight = try? await flightTrackingService.getFlightDetails(flight) {
                    flight = updatedFlight
                    print("✅ Updated flight with API data (airports, times)")
                } else {
                    print("⚠️ Could not fetch flight details, using existing flight data")
                }
                
                // Then get the current status
                let status = try await flightTrackingService.trackFlight(flight)
                flight.currentStatus = status
                
                // Create delay event if flight is delayed or cancelled
                // Note: If status is .scheduled, the flight exists but hasn't departed yet
                if status == .delayed || status == .cancelled {
                    let delayDuration = calculateDelayDuration(flight: flight, status: status)
                    let delayEvent = DelayEvent(
                        type: status == .cancelled ? .cancellation : .delay,
                        duration: delayDuration,
                        actualTime: status == .cancelled ? nil : Date(),
                        reason: status == .cancelled ? "Flight cancelled by airline" : "Operational delay"
                    )
                    flight.delayEvents.append(delayEvent)
                } else if status == .scheduled {
                    // Flight is scheduled but not yet active - this is normal for future flights
                    print("Flight is scheduled - will track when it becomes active")
                }
                
                await MainActor.run {
                    self.flight = flight
                    isLoading = false
                    checkEligibilityIfNeeded()
                }
            } catch let error as FlightRadar24Error {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Unable to check flight status: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func calculateDelayDuration(flight: Flight, status: FlightStatus) -> TimeInterval {
        // Simulate delay duration (in a real app, this would come from the tracking service)
        // For delays, simulate 3-5 hours, for cancellations use 0
        
        // Testing: Use specific delays for test flight codes
        let flightCode = "\(flight.airline.code)\(flight.flightNumber)"
        if flightCode == "DELAY001" {
            return 4.5 * 3600.0 // 4.5 hours delay
        } else if flightCode == "DELAY002" {
            return 3.0 * 3600.0 // 3 hours delay
        }
        
        if status == .cancelled {
            return 0
        }
        // Random delay between 3-5 hours for demonstration
        let delayHours = Double.random(in: 3.0...5.0)
        return delayHours * 3600.0
    }
    
    func checkEligibility() {
        guard let flight = flight else { return }
        checkEligibilityIfNeeded()
    }
    
    private func checkEligibilityIfNeeded() {
        guard let flight = flight else {
            eligibility = nil
            return
        }
        
        // Always check eligibility to show information, even if no delay
        isCheckingEligibility = true
        errorMessage = nil
        
        Task {
            // If there's an active delay, check actual eligibility
            if flight.hasActiveDelay, let delayEvent = flight.latestDelayEvent {
                let result = await eligibilityService.checkEligibility(for: flight, delayEvent: delayEvent)
                await MainActor.run {
                    eligibility = result
                    isCheckingEligibility = false
                }
            } else {
                // No delay - show that flight is on time
                let result = CompensationEligibility(
                    isEligible: false,
                    amount: 0,
                    reason: "No delay detected. Your flight appears to be on time.",
                    confidence: 1.0
                )
                await MainActor.run {
                    eligibility = result
                    isCheckingEligibility = false
                }
            }
        }
    }
}

