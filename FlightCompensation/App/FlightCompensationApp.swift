import SwiftUI
import UIKit
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct FlightCompensationApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
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
                        ),
                        authService: dependencies.authenticationService
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

