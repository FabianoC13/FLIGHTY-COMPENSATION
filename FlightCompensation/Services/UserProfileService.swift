import Foundation
import SwiftUI

final class UserProfileService: ObservableObject {
    static let shared = UserProfileService()
    
    @AppStorage("hasOnboarded") var hasOnboarded: Bool = false
    @Published var userProfile: UserProfile?
    
    private let profileKey = "user_profile_data"
    
    private init() {
        loadProfile()
    }
    
    func saveProfile(_ profile: UserProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
            self.userProfile = profile
            self.hasOnboarded = true
        }
    }
    
    func loadProfile() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.userProfile = profile
        }
    }
    
    func clearProfile() {
        UserDefaults.standard.removeObject(forKey: profileKey)
        self.userProfile = nil
        self.hasOnboarded = false
    }
}
