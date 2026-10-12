import Foundation
import SwiftUI

final class UserProfileService: ObservableObject {
    static let shared = UserProfileService()
    
    @AppStorage("hasOnboarded") var hasOnboarded: Bool = false
    @Published var userProfile: UserProfile?
    
    private let profileKey = "user_profile_data"
    
    private init() {
        KeychainStore.migrateFromUserDefaults(profileKey)
        loadProfile()
    }
    
    func saveProfile(_ profile: UserProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            KeychainStore.set(data, for: profileKey)
            self.userProfile = profile
            self.hasOnboarded = true
        }
    }
    
    func loadProfile() {
        if let data = KeychainStore.data(for: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.userProfile = profile
        }
    }
    
    func clearProfile() {
        KeychainStore.remove(profileKey)
        self.userProfile = nil
        self.hasOnboarded = false
    }
}
