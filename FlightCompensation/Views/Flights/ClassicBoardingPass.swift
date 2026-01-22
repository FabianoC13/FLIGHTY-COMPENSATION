import SwiftUI

/// Classic "OG" airline boarding pass style card - dark theme adaptation
struct ClassicBoardingPass: View {
    let flight: Flight
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var isTorn = false
    @State private var offset: CGFloat = 0
    @State private var isSwiped = false
    
    var body: some View {
        ZStack {
            // Background Delete Button (circular with text below) - only visible when swiping
            if offset < 0 {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Button(action: {
                            HapticsManager.shared.notification(type: .warning)
                            withAnimation(.spring()) {
                                offset = -500 // Slide out completely
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onDelete()
                            }
                        }) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundColor(.white)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Text("Delete")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxHeight: .infinity)
                    .padding(.trailing, 20)
                    .opacity(Double(-offset) / 90.0) // Fade in as user swipes
                }
            }
            
            // The Card
            HStack(spacing: 0) {
                // Main ticket section
                mainSection
                    .zIndex(1)
                
                // Perforated divider stays with main section
                perforatedDivider
                    .zIndex(1)
                
                // Stub section (tear-off style)
                stubSection
                    .rotationEffect(.degrees(isTorn ? 15 : 0), anchor: .topLeading)
                    .offset(x: isTorn ? 60 : 0, y: isTorn ? 20 : 0)
                    .opacity(isTorn ? 0 : 1)
                    .zIndex(0)
            }
            .contentShape(Rectangle())
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onChanged { value in
                        // Only allow horizontal swipe to the left
                        if value.translation.width < 0 && abs(value.translation.width) > abs(value.translation.height) {
                            let maxOffset: CGFloat = -90
                            offset = max(value.translation.width, maxOffset)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if value.translation.width < -50 {
                                offset = -90
                                isSwiped = true
                            } else {
                                offset = 0
                                isSwiped = false
                            }
                        }
                    }
            )
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        if isSwiped {
                            withAnimation(.spring()) {
                                offset = 0
                                isSwiped = false
                            }
                        } else {
                            // Trigger tear-off animation
                            withAnimation(.easeInOut(duration: 0.4)) {
                                isTorn = true
                            }
                            
                            // Haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .heavy)
                            generator.impactOccurred()
                            
                            // Delay navigation to let animation play
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onTap()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    isTorn = false
                                }
                            }
                        }
                    }
            )
        }
    }
    
    // MARK: - Main Section (Left 70%)
    private var mainSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header bar - Airline Branding
            HStack {
                Image(systemName: "airplane")
                    .foregroundStyle(flight.airline.brandContentColor)
                Text(flight.airline.name.uppercased())
                    .font(.custom("HelveticaNeue-Bold", size: 11))
                    .foregroundStyle(flight.airline.brandContentColor)
                Spacer()
                statusBadge
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(flight.airline.brandColor) // Dynamic Airline Color
            
            // Route section
            HStack(alignment: .top, spacing: 20) {
                // Departure
                VStack(alignment: .leading, spacing: 2) {
                    Text("FROM:")
                        .font(.custom("HelveticaNeue-Medium", size: 9))
                        .foregroundStyle(.white.opacity(0.5))
                    Text(flight.departureAirport.code)
                        .font(.custom("HelveticaNeue-Bold", size: 28))
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(.white)
                    Text(flight.departureAirport.city.uppercased())
                        .font(.custom("HelveticaNeue-Medium", size: 10))
                        .foregroundStyle(.white.opacity(0.7))
                    Text(formatDate(flight.scheduledDeparture))
                        .font(.custom("HelveticaNeue", size: 9))
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                // Flight path indicator
                VStack(spacing: 4) {
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(.white.opacity(0.3)).frame(width: 4, height: 4)
                        Rectangle()
                            .fill(.white.opacity(0.2))
                            .frame(height: 1)
                        Image(systemName: "airplane")
                            .font(.system(size: 14))
                            .foregroundStyle(PremiumTheme.electricBlue)
                        Rectangle()
                            .fill(.white.opacity(0.2))
                            .frame(height: 1)
                        Circle().fill(.white.opacity(0.3)).frame(width: 4, height: 4)
                    }
                    Spacer()
                }
                .frame(width: 60)
                
                // Arrival
                VStack(alignment: .trailing, spacing: 2) {
                    Text("TO:")
                        .font(.custom("HelveticaNeue-Medium", size: 9))
                        .foregroundStyle(.white.opacity(0.5))
                    Text(flight.arrivalAirport.code)
                        .font(.custom("HelveticaNeue-Bold", size: 28))
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(.white)
                    Text(flight.arrivalAirport.city.uppercased())
                        .font(.custom("HelveticaNeue-Medium", size: 10))
                        .foregroundStyle(.white.opacity(0.7))
                    Text(formatTime(flight.scheduledArrival))
                        .font(.custom("HelveticaNeue", size: 9))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16) // Increased internal spacing for "Airy" feel
            
            // Bottom info bar
            HStack(spacing: 16) {
                infoItem(label: "FLIGHT", value: flight.displayFlightNumber)
                infoItem(label: "DATE", value: shortDate(flight.scheduledDeparture))
                if let claimDate = flight.claimDate {
                    infoItem(label: "CLAIMED", value: shortDate(claimDate))
                } else {
                    infoItem(label: "TIME", value: formatTime(flight.scheduledDeparture))
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .background(Material.ultraThin) // Glassmorphism
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Stub Section (Right tear-off)
    private var stubSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(flight.departureAirport.code)
                .font(.custom("HelveticaNeue-Bold", size: 18))
                .foregroundStyle(.white)
            
            Image(systemName: "arrow.down")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.5))
            
            Text(flight.arrivalAirport.code)
                .font(.custom("HelveticaNeue-Bold", size: 18))
                .foregroundStyle(.white)
            
            Spacer()
            
            // Barcode removed as requested
        }
        .padding(10)
        .frame(width: 70)
        .background(Material.ultraThin) // Glassmorphism for stub too
        .overlay(Color.black.opacity(0.2)) // Slightly darker for stub
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Perforated Divider
    private var perforatedDivider: some View {
        VStack(spacing: 4) {
             ForEach(0..<12, id: \.self) { _ in
                 Circle()
                     .fill(Color.white.opacity(0.3))
                     .frame(width: 4, height: 4)
             }
        }
        .padding(.vertical, 4)
        .background(Color.clear)
    }
    
    // MARK: - Helper Views
    private var statusBadge: some View {
        // Prioritize Claim Status if it exists and is not 'notStarted'
        let displayText = shouldShowClaimStatus ? flight.claimStatus.rawValue.uppercased() : flight.status.displayName.uppercased()
        
        return Text(displayText)
            .font(.custom("HelveticaNeue-Bold", size: 9))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.4))
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(statusColor.opacity(0.5), lineWidth: 1)
            )
    }
    
    private var shouldShowClaimStatus: Bool {
        flight.claimStatus != .notStarted
    }
    
    private var statusColor: Color {
        if shouldShowClaimStatus {
            return Color(hex: flight.claimStatus.colorHex)
        }
        
        switch flight.status {
        case .delayed, .cancelled:
            return .orange
        case .arrived:
            return .green
        default:
            return .white
        }
    }
    
    // Glow color based on status
    private var statusGlowColor: Color {
        switch flight.status {
        case .delayed, .cancelled:
            return .orange
        case .arrived:
            return .green
        case .scheduled, .departed, .onTime:
            return PremiumTheme.electricBlue
        }
    }

    private func infoItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.custom("HelveticaNeue-Medium", size: 8))
                .foregroundStyle(.white.opacity(0.4))
            Text(value)
                .font(.custom("HelveticaNeue-Bold", size: 12))
                .foregroundStyle(.white)
        }
    }
    
    // MARK: - Date Formatting
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: date).uppercased()
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
    }
}

// Preview disabled - requires SampleData
// #Preview {
//     ZStack {
//         Color.black.ignoresSafeArea()
//         ClassicBoardingPass(flight: SampleData.sampleFlight) {}
//             .padding()
//     }
// }
