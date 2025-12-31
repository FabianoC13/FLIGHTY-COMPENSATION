import SwiftUI

struct WelcomeCarouselView: View {
    @State private var currentPage = 0
    @State private var showOnboarding = false
    
    let slides = [
        WelcomeSlide(
            image: "airplane.departure",
            title: "FLIGHT DELAYED?",
            subtitle: "Don't let airlines keep your money. Claim up to €600."
        ),
        WelcomeSlide(
            image: "bolt.fill",
            title: "1-CLICK CLAIMS",
            subtitle: "Set up your profile once. File claims instantly."
        ),
        WelcomeSlide(
            image: "lock.shield.fill",
            title: "SECURE & PRIVATE",
            subtitle: "Your data is encrypted and used only for claims."
        )
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                WorldMapBackground()
                
                VStack {
                    TabView(selection: $currentPage) {
                        ForEach(0..<slides.count, id: \.self) { index in
                            VStack(spacing: 20) {
                                if index == 0 {
                                    FlightDelayAnimationView()
                                        .frame(height: 150)
                                        .padding(.bottom, 20)
                                } else {
                                    Image(systemName: slides[index].image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 100)
                                        .foregroundStyle(PremiumTheme.primaryGradient)
                                        .shadow(color: PremiumTheme.electricBlue.opacity(0.5), radius: 20, x: 0, y: 0)
                                }
                                
                                Text(slides[index].title)
                                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                                
                                Text(slides[index].subtitle)
                                    .font(.body)
                                    .foregroundStyle(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .frame(height: 400)
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        GradientButton(
                            title: currentPage == slides.count - 1 ? "GET STARTED" : "NEXT",
                            icon: currentPage == slides.count - 1 ? "checkmark" : "arrow.right",
                            gradient: PremiumTheme.goldGradient,
                            action: {
                                if currentPage < slides.count - 1 {
                                    withAnimation {
                                        currentPage += 1
                                    }
                                } else {
                                    showOnboarding = true
                                }
                            }
                        )
                        .padding(.horizontal, 24)
                        
                        if currentPage < slides.count - 1 {
                            Button("Skip") {
                                showOnboarding = true
                            }
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationDestination(isPresented: $showOnboarding) {
                OnboardingView()
            }
        }
    }
}

struct WelcomeSlide {
    let image: String
    let title: String
    let subtitle: String
}

#Preview {
    WelcomeCarouselView()
}
