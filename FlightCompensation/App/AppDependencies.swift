import Foundation
import Combine

@MainActor
final class AppDependencies: ObservableObject {
    let flightTrackingService: FlightTrackingService
    let eligibilityService: EligibilityService
    let walletImportService: WalletImportService
    let flightStorageService: FlightStorageServiceProtocol
    let authenticationService: AuthenticationService
    
    init(
        flightTrackingService: FlightTrackingService? = nil,
        eligibilityService: EligibilityService? = nil,
        walletImportService: WalletImportService? = nil,
        flightStorageService: FlightStorageServiceProtocol? = nil,
        authenticationService: AuthenticationService? = nil
    ) {
        // Use real FlightRadar24 API if configured, otherwise use mock
        if Config.useRealFlightTracking {
            self.flightTrackingService = flightTrackingService ?? FlightRadar24Service(apiKey: Config.flightRadar24APIKey)
        } else {
            self.flightTrackingService = flightTrackingService ?? MockFlightTrackingService()
        }
        
        self.eligibilityService = eligibilityService ?? EU261EligibilityService()
        self.walletImportService = walletImportService ?? MockWalletImportService()
        self.flightStorageService = flightStorageService ?? FlightStorageService()
        self.authenticationService = authenticationService ?? AuthenticationService()
    }
}


