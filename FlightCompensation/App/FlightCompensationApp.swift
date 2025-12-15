import SwiftUI

@main
struct FlightCompensationApp: App {
    @StateObject private var dependencies = AppDependencies()
    
    var body: some Scene {
        WindowGroup {
            FlightsListView(
                viewModel: FlightsListViewModel(
                    flightTrackingService: dependencies.flightTrackingService
                )
            )
        }
    }
}

