import Foundation
import Combine
import CoreLocation

@MainActor
final class FlightDetailViewModel: ObservableObject {
    @Published var flight: Flight?
    @Published var timelineEvents: [DelayEvent] = []
    @Published var eligibility: CompensationEligibility?
    @Published var isLoading: Bool = false
    @Published var isCheckingEligibility: Bool = false
    @Published var errorMessage: String?
    @Published var planePosition: FlightPosition? = nil
    @Published var planeSpeedKmph: Double? = nil
    @Published var planeAltitude: Double? = nil
    @Published var planeETA: Date? = nil

    private let flightTrackingService: FlightTrackingService
    private let eligibilityService: EligibilityService
    private var cancellables = Set<AnyCancellable>()
    private var positionsTask: Task<Void, Never>? 
    private var lastPosition: FlightPosition? = nil
    private let headingSmoother = HeadingSmoother()
    
    // Callback to notify parent (List) of changes
    var onFlightUpdate: ((Flight) -> Void)?
    
    init(
        flight: Flight? = nil,
        flightTrackingService: FlightTrackingService,
        eligibilityService: EligibilityService
    ) {
        self.flight = flight
        self.flightTrackingService = flightTrackingService
        self.eligibilityService = eligibilityService
    }
    
    func loadFlight(_ flight: Flight, skipRefresh: Bool = false) {
        self.flight = flight
        self.timelineEvents = flight.delayEvents
        if !skipRefresh {
            startPositionUpdates(for: flight)
            trackFlight()
        }
        // Check eligibility after tracking completes (handled in trackFlight)
    }
    
    func trackFlight() {
        guard var flight = flight else { return }
        
        isLoading = true
        errorMessage = nil
        
        print("➡️ [Detail] Starting trackFlight for: \(flight.displayFlightNumber) — currentStatus: \(flight.currentStatus.displayName), route: \(flight.route)")
        
        Task {
            do {
                // First, get complete flight details (airports, times, etc.)
                if let updatedFlight = try? await flightTrackingService.getFlightDetails(flight) {
                    print("⬅️ [Detail] getFlightDetails returned for \(flight.displayFlightNumber): route=\(updatedFlight.route), status=\(updatedFlight.currentStatus.displayName)")
                    flight = updatedFlight
                    print("✅ Updated flight with API data (airports, times): route=\(flight.route)")
                } else {
                    print("⚠️ Could not fetch flight details for \(flight.displayFlightNumber), using existing flight data: route=\(flight.route)")
                }
                
                // Then get the current status
                let status = try await flightTrackingService.trackFlight(flight)
                print("⬅️ [Detail] trackFlight returned status=\(status.displayName) for \(flight.displayFlightNumber)")
                var delayEvents = flight.delayEvents

                // If status changed, notify the user
                if status != flight.currentStatus {
                    NotificationManager.shared.scheduleLocalNotification(title: "Flight status updated", body: "\(flight.displayFlightNumber): \(status.displayName)")
                }
                
                // Create delay event if flight is delayed or cancelled
                // Note: If status is .scheduled, the flight exists but hasn't departed yet
                if status == .delayed || status == .cancelled {
                    if delayEvents.isEmpty {
                        // No delay events from the service, simulate one for UI/testing
                        let delayDuration = calculateDelayDuration(flight: flight, status: status)
                        let delayEvent = DelayEvent(
                            type: status == .cancelled ? .cancellation : .delay,
                            duration: delayDuration,
                            actualTime: status == .cancelled ? nil : Date(),
                            reason: status == .cancelled ? "Flight cancelled by airline" : "Operational delay"
                        )
                        delayEvents.append(delayEvent)
                        print("✅ [Detail] Appended simulated delay event: \(delayEvent.type) duration=\(delayEvent.duration/3600)h")
                    } else {
                        // Service already provided delay/cancellation events - don't duplicate
                        print("ℹ️ [Detail] Delay events already provided by service; skipping simulated append")
                    }
                } else if status == .scheduled {
                    // Flight is scheduled but not yet active - this is normal for future flights
                    print("Flight is scheduled - will track when it becomes active")
                }
                
                // Create new Flight instance with updated values, preserving claim data
                let updatedFlight = Flight(
                    id: flight.id,
                    flightNumber: flight.flightNumber,
                    airline: flight.airline,
                    departureAirport: flight.departureAirport,
                    arrivalAirport: flight.arrivalAirport,
                    scheduledDeparture: flight.scheduledDeparture,
                    scheduledArrival: flight.scheduledArrival,
                    status: flight.status,
                    currentStatus: status,
                    delayEvents: delayEvents,
                    claimStatus: flight.claimStatus,
                    claimReference: flight.claimReference
                )
                flight = updatedFlight
                
                print("⬅️ [Detail] Final flight object: \(flight.displayFlightNumber) — currentStatus: \(flight.currentStatus.displayName), route: \(flight.route)")
                
                await MainActor.run {
                    self.flight = flight
                    self.timelineEvents = flight.delayEvents
                    isLoading = false
                    checkEligibilityIfNeeded()
                    // start listening to possible live positions for this flight
                    self.startPositionUpdates(for: flight)
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
        let flightCode = "\(flight.airline.code)\(flight.flightNumber)".uppercased()
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
        guard flight != nil else { return }
        checkEligibilityIfNeeded()
    }

    private func startPositionUpdates(for flight: Flight) {
        // Cancel previous task if any
        positionsTask?.cancel()
        positionsTask = Task { [weak self] in
            guard let self = self else { return }
            self.lastPosition = nil
            for await position in self.flightTrackingService.positionUpdates(flight) {
                await MainActor.run {
                    // Update full position
                    // Smooth heading before exposing it to the view
                    var pos = position
                    if let heading = position.heading {
                        let smoothed = self.headingSmoother.update(with: heading)
                        pos = FlightPosition(latitude: pos.latitude, longitude: pos.longitude, altitude: pos.altitude, heading: smoothed, speed: pos.speed, timestamp: pos.timestamp)
                    }

                    self.planePosition = pos
                    self.planeAltitude = pos.altitude

                    // Update speed
                    if let s = pos.speed, s > 0 {
                        // Trust API/Simulator speed if available
                        self.planeSpeedKmph = s * 3.6
                    } else if let last = self.lastPosition {
                        // Fallback: Compute speed from displacement
                        let lastLoc = CLLocation(latitude: last.latitude, longitude: last.longitude)
                        let currLoc = CLLocation(latitude: pos.latitude, longitude: pos.longitude)
                        let dist = currLoc.distance(from: lastLoc)
                        let dt = pos.timestamp.timeIntervalSince(last.timestamp)
                        
                        // Sanity check: dt must be reasonable (> 1s) to avoid division by near-zero
                        if dt > 1.0 {
                            let speedMps = dist / dt
                            // Sanity check: cap at 1200 km/h (approx Mach 0.98) to filter GPS jumps
                            let calculatedKmph = speedMps * 3.6
                            if calculatedKmph < 1200 {
                                self.planeSpeedKmph = calculatedKmph
                            }
                        }
                    }

                    // Compute ETA if we have speed and destination coordinate
                    if let speedKmph = self.planeSpeedKmph, speedKmph > 1.0, let dest = flight.arrivalAirport.coordinate {
                        let currLoc = CLLocation(latitude: pos.latitude, longitude: pos.longitude)
                        let destLoc = CLLocation(latitude: dest.latitude, longitude: dest.longitude)
                        let remainingMeters = currLoc.distance(from: destLoc)
                        let speedMps = speedKmph / 3.6
                        let eta = Date().addingTimeInterval(remainingMeters / speedMps)
                        self.planeETA = eta
                    }

                    self.lastPosition = pos
                }
            }
        }
    }

    deinit {
        positionsTask?.cancel()
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

