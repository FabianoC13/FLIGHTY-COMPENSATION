import SwiftUI

@main
struct FlightCompensationApp: App {
    @StateObject private var dependencies = AppDependencies()
    @StateObject private var userProfileService = UserProfileService.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if userProfileService.hasOnboarded {
                    FlightsListView(
                        viewModel: FlightsListViewModel(
                            flightTrackingService: dependencies.flightTrackingService,
                            flightStorageService: dependencies.flightStorageService
                        )
                    )
                } else {
                    WelcomeCarouselView()
                }
            }
            .onAppear {
                NotificationManager.shared.requestAuthorization { granted in
                    print("Notifications authorized: \(granted)")
                }
                UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
            }
        }
    }
}

