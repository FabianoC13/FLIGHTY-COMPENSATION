import Foundation

protocol EligibilityService {
    func checkEligibility(for flight: Flight, delayEvent: DelayEvent) async -> CompensationEligibility
}


