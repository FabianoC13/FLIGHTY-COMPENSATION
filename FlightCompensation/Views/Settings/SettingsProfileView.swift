import SwiftUI
import AuthenticationServices
import GoogleSignIn
import FirebaseAuth

struct SettingsProfileView: View {
    @ObservedObject var authService: AuthenticationService
    @ObservedObject var userProfileService = UserProfileService.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                PremiumTheme.midnightBlueStart.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header / Avatar
                        VStack(spacing: 16) {
                            Circle()
                                .fill(authService.isAnonymous ? Color.gray.opacity(0.3) : PremiumTheme.goldStart)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: authService.isAnonymous ? "person.crop.circle" : "checkmark.seal.fill")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.white)
                                )
                            
                            VStack(spacing: 4) {
                                Text(userProfileService.userProfile?.fullName ?? "Guest User")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                
                                Text(authService.isAnonymous ? "Anonymous Account" : (authService.currentUser?.email ?? "Linked Account"))
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                        .padding(.top, 20)
                        
                        // Account Status Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Account Security")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.8))
                            
                            if authService.isAnonymous {
                                // Warning
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Your account is temporary")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white)
                                        
                                        Text("Link a social account to permanently save your flight history and claims.")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.7))
                                    }
                                }
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                            } else {
                                // Success
                                HStack {
                                    Image(systemName: "lock.shield.fill")
                                        .foregroundStyle(.green)
                                    Text("Your data is securely backed up.")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Linking Buttons
                        if authService.isAnonymous {
                            VStack(spacing: 16) {
                                // Sign in with Apple
                                SignInWithAppleButton(
                                    onRequest: { _ in
                                        authService.startAppleSignIn()
                                    },
                                    onCompletion: { _ in }
                                )
                                .signInWithAppleButtonStyle(.white)
                                .frame(height: 50)
                                .cornerRadius(8)
                                .padding(.horizontal)
                                
                                // Sign in with Google
                                Button(action: {
                                    startGoogleSignIn()
                                }) {
                                    HStack {
                                        Image(systemName: "globe") // Ideally Google Logo
                                            .font(.title3)
                                        Text("Sign in with Google")
                                            .font(.headline)
                                    }
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        Spacer()
                        
                        // Sign Out (Only if not anon, technically difficult if anon but useful for debug)
                        if !authService.isAnonymous {
                            Button(action: {
                                try? authService.signOut()
                            }) {
                                Text("Sign Out")
                                    .font(.headline)
                                    .foregroundStyle(.red)
                            }
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func startGoogleSignIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        
        Task {
            try? await authService.linkGoogleAccount(presenting: rootVC)
        }
    }
}

extension UserProfile {
    var fullName: String {
        guard !firstName.isEmpty else { return "Guest" }
        return "\(firstName) \(lastName)"
    }
}
