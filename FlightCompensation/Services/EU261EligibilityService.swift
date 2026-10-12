import Foundation

/// Bridges app models (`Flight`, `DelayEvent`, the passenger's answers) to `EU261Rules`.
final class EU261EligibilityService: EligibilityService {

    private let airports: AirportDatabase

    init(airports: AirportDatabase = .shared) {
        self.airports = airports
    }

    func checkEligibility(for flight: Flight, delayEvent: DelayEvent) async -> CompensationEligibility {
        assess(flight: flight, delayEvent: delayEvent, report: DisruptionReportStore.load(for: flight.id))
    }

    /// Synchronous variant used by the claim flow while the passenger answers questions.
    func assess(flight: Flight, delayEvent: DelayEvent?, report: DisruptionReport?) -> CompensationEligibility {
        if report?.alreadyCompensated == true {
            return CompensationEligibility(
                isEligible: false, amount: 0,
                reason: "The airline already compensated you for this flight, so there's nothing left to claim.",
                confidence: 1.0
            )
        }

        let input = makeInput(flight: flight, delayEvent: delayEvent, report: report)
        let result = EU261Rules.assess(input)

        return CompensationEligibility(
            isEligible: result.outcome != .notEligible,
            amount: Decimal(result.amount),
            currency: result.currency,
            reason: result.explanation,
            confidence: result.confidence,
            regulation: result.regime?.rawValue,
            distanceKm: result.distanceKm,
            needsMoreInformation: result.outcome == .needsInformation,
            warnings: result.warnings.isEmpty ? nil : result.warnings
        )
    }

    func makeInput(flight: Flight, delayEvent: DelayEvent?, report: DisruptionReport?) -> EU261Input {
        let dep = airports.lookup(flight.departureAirport.code)
        let arr = airports.lookup(flight.arrivalAirport.code)

        // Prefer coordinates from flight data, fall back to the bundled database.
        var distance: Double?
        if let lat1 = flight.departureAirport.latitude ?? dep?.latitude,
           let lon1 = flight.departureAirport.longitude ?? dep?.longitude,
           let lat2 = flight.arrivalAirport.latitude ?? arr?.latitude,
           let lon2 = flight.arrivalAirport.longitude ?? arr?.longitude {
            distance = AirportDatabase.greatCircleDistanceKm(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2)
        }

        let isCancellation = delayEvent?.type == .cancellation || flight.currentStatus == .cancelled
        let disruption: EU261Input.Disruption
        if isCancellation {
            var info = EU261Input.CancellationInfo()
            info.noticeDaysBeforeDeparture = report?.notice?.days
            if let offered = report?.alternativeOffered {
                info.reroutingAnswered = true
                if offered, let report {
                    info.rerouting = .init(departedEarlierByMinutes: report.alternativeDeparture.minutes,
                                           arrivedLaterByMinutes: report.alternativeArrival.minutes)
                }
            }
            disruption = .cancellation(info)
        } else {
            // Measured arrival delay from flight data wins; otherwise the passenger's answer.
            var minutes: Int?
            if let event = delayEvent, event.isDurationKnown {
                minutes = Int(event.duration / 60)
            } else if let answer = report?.arrivalDelay {
                minutes = answer.minutes
            }
            disruption = .delay(arrivalDelayMinutes: minutes)
        }

        let passengerReason = report?.airlineReason.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return EU261Input(
            departureIATA: flight.departureAirport.code,
            arrivalIATA: flight.arrivalAirport.code,
            departureCountry: dep?.countryCode,
            arrivalCountry: arr?.countryCode,
            distanceKm: distance,
            operatingCarrier: flight.airline.code,
            disruption: disruption,
            reportedReason: passengerReason.isEmpty ? delayEvent?.reason : passengerReason
        )
    }
}
