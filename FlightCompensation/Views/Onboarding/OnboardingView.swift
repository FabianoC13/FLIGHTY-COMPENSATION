import SwiftUI

struct OnboardingView: View {
    @StateObject private var userProfileService = UserProfileService.shared
    @State private var userProfile = UserProfile()
    @Environment(\.dismiss) private var dismiss
    @State private var showDetailedSetup = false
    
    var body: some View {
        ZStack {
            // 1. Background
            WorldMapBackground()
            
            // 2. Content
            ScrollView {
                VStack(spacing: 30) {
                    Spacer(minLength: 40)
                    
                    // Header (Icon & Title)
                    VStack(spacing: 16) {
                        Image(systemName: "airplane")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(PremiumTheme.primaryGradient)
                            .frame(width: 80, height: 80)
                            .shadow(color: PremiumTheme.electricBlue.opacity(0.5), radius: 20)
                            
                        Text("FLIGHTY CLAIM")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .tracking(2)
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                        
                        Text("INSTANT COMPENSATION")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(PremiumTheme.electricBlue)
                            .tracking(4)
                    }
                    .padding(.bottom, 20)
                    
                    // Form Glass Card
                    VStack(spacing: 24) {
                        Text("Please enter your details")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 20) {
                            PremiumTextField(
                                placeholder: "First Name",
                                text: $userProfile.firstName,
                                contentType: .givenName
                            )
                            
                            PremiumTextField(
                                placeholder: "Last Name",
                                text: $userProfile.lastName,
                                contentType: .familyName
                            )
                            
                            PremiumTextField(
                                placeholder: "Email Address",
                                text: $userProfile.email,
                                contentType: .emailAddress,
                                keyboardType: .emailAddress
                            )
                        }
                    }
                    .padding(30)
                    .glassCard(cornerRadius: 30)
                    .padding(.horizontal, 20)
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        GradientButton(
                            title: "GET STARTED",
                            icon: "arrow.right",
                            gradient: PremiumTheme.primaryGradient,
                            action: {
                                showDetailedSetup = true
                            },
                            isDisabled: !userProfile.isValid
                        )
                        .padding(.horizontal, 20)
                        
                        Button(action: {
                            // Action for help or skip if needed
                        }) {
                            Text("Already have an account? Sign In")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.6))
                                .underline()
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            .scrollIndicators(.hidden)
        }
        .navigationDestination(isPresented: $showDetailedSetup) {
            ProfileSetupView(userProfile: $userProfile) {
                // When detailed setup is done, we dismiss the entire onboarding flow
                userProfileService.saveProfile(userProfile)
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationView {
        OnboardingView()
    }
}
