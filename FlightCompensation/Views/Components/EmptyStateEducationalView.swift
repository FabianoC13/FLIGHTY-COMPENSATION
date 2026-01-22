import SwiftUI

struct EmptyStateEducationalView: View {
    let onAddFlight: () -> Void
    
    var body: some View {
        VStack(spacing: 28) {
            // Airplane Illustration with Delay Badge
            ZStack {
                // Airplane graphic
                ZStack {
                    // Airplane body shadow/glow
                    Image(systemName: "airplane")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(PremiumTheme.electricBlue.opacity(0.3))
                        .blur(radius: 20)
                        .offset(x: -5, y: 5)
                    
                    // Main airplane
                    Image(systemName: "airplane")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    PremiumTheme.electricBlue.opacity(0.8),
                                    PremiumTheme.electricBlue.opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: PremiumTheme.electricBlue.opacity(0.4), radius: 15, x: 0, y: 0)
                }
                .rotationEffect(.degrees(-15))
                
                // "DELAYED" Badge
                Text("DELAYED")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.95, green: 0.35, blue: 0.35))
                    )
                    .shadow(color: Color(red: 0.95, green: 0.35, blue: 0.35).opacity(0.3), radius: 8, x: 0, y: 2)
                    .offset(x: 35, y: 30)
            }
            .frame(height: 120)
            .padding(.top, 20)
            
            // Educational Content
            VStack(spacing: 12) {
                Text("Delayed flights")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Delayed 3 hours or more? You could get up to €600 according to air passenger rights regulations.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
                
                Text("Add your first flight to start tracking compensation eligibility")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.top, 4)
            }
            
            // Call to Action Button
            GradientButton(
                title: "Start Claim",
                icon: "plus",
                gradient: PremiumTheme.primaryGradient,
                action: onAddFlight
            )
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ZStack {
        WorldMapBackground()
        
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
            
            EmptyStateEducationalView(onAddFlight: {})
        }
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.06, green: 0.07, blue: 0.12).opacity(0.95),
                            Color(red: 0.03, green: 0.03, blue: 0.06).opacity(0.98)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .padding(.horizontal, 12)
    }
}
