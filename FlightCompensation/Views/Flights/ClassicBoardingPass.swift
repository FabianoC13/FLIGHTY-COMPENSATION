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
                    infoItem(label: "CLAIMED", value: shortDate(claimDate), valueColor: PremiumTheme.goldStart, isBold: true)
                } else {
                    infoItem(label: "TIME", value: formatTime(flight.scheduledDeparture))
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.6)) // Midnight Tint
        .background(Material.ultraThin) // Glassmorphism
        .clipShape(TicketShape(side: .left, cornerRadius: 12, cutoutRadius: 8))
        .overlay(
            TicketShape(side: .left, cornerRadius: 12, cutoutRadius: 8)
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
        .background(Color.black.opacity(0.6)) // Midnight Glass
        .background(Material.ultraThin) // Glassmorphism for stub too
        .overlay(Color.black.opacity(0.2)) // Slightly darker for stub
        .clipShape(TicketShape(side: .right, cornerRadius: 12, cutoutRadius: 8))
        .overlay(
            TicketShape(side: .right, cornerRadius: 12, cutoutRadius: 8)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Perforated Divider
    private var perforatedDivider: some View {
        Color.clear
            .frame(width: 4) // Tighter gap
            .overlay(
                Line()
                    // lineWidth 4 matches gap
                    // dash [0, 8] = 4px dot + 4px space (classic perforation)
                    .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [0, 8]))
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.vertical, 8) // Reduced padding to 8 to touch the cutout start
            )
    }

    struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            // Fix alignment: Draw down the CENTER of the frame, not the left edge
            path.move(to: CGPoint(x: rect.midX, y: 0))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.height))
            return path
        }
    }
    
    // Custom shape for the ticket "bite" effect
    struct TicketShape: Shape {
        let side: Side
        let cornerRadius: CGFloat
        let cutoutRadius: CGFloat
        
        enum Side {
            case left, right
        }
        
        func path(in rect: CGRect) -> Path {
            var path = Path()
            
            if side == .left {
                // Top Left (Rounded) - Use Tangent Arc for perfect curve
                path.move(to: CGPoint(x: 0, y: cornerRadius))
                path.addArc(tangent1End: CGPoint(x: 0, y: 0), tangent2End: CGPoint(x: cornerRadius, y: 0), radius: cornerRadius)
                
                // Top Edge to Cutout
                path.addLine(to: CGPoint(x: rect.width - cutoutRadius, y: 0))
                
                // Top Right Bite (Concave) - 180 -> 90 (Decreasing/CCW)
                path.addArc(center: CGPoint(x: rect.width, y: 0), radius: cutoutRadius, startAngle: .degrees(180), endAngle: .degrees(90), clockwise: true)
                
                // Right Edge
                path.addLine(to: CGPoint(x: rect.width, y: rect.height - cutoutRadius))
                
                // Bottom Right Bite (Concave) - 270 -> 180 (Decreasing/CCW)
                path.addArc(center: CGPoint(x: rect.width, y: rect.height), radius: cutoutRadius, startAngle: .degrees(270), endAngle: .degrees(180), clockwise: true)
                
                // Bottom Edge to Corner
                path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))
                
                // Bottom Left (Rounded) - Tangent Arc
                path.addArc(tangent1End: CGPoint(x: 0, y: rect.height), tangent2End: CGPoint(x: 0, y: rect.height - cornerRadius), radius: cornerRadius)
                path.closeSubpath()
                
            } else {
                // Right Stub
                // Top Right (Rounded) - Tangent Arc
                path.move(to: CGPoint(x: rect.width - cornerRadius, y: 0))
                path.addLine(to: CGPoint(x: cutoutRadius, y: 0))
                
                // Top Left Bite (Concave) - 360/0 -> 90 (Increasing/CW) -> Wait, 0->90 is increasing. But we want 0->90 to carve IN.
                // Center (0,0). Start 0(Right). End 90(Down).
                // 0->90 is "into" the rect. Correct.
                path.addArc(center: CGPoint(x: 0, y: 0), radius: cutoutRadius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
                
                // Left Edge
                path.addLine(to: CGPoint(x: 0, y: rect.height - cutoutRadius))
                
                // Bottom Left Bite (Concave) - 270 -> 360/0 (Increasing/CW)
                // Center (0, h). Start 270(Up). End 360(Right).
                path.addArc(center: CGPoint(x: 0, y: rect.height), radius: cutoutRadius, startAngle: .degrees(270), endAngle: .degrees(360), clockwise: false)
                
                // Bottom Edge
                path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: rect.height))
                
                // Bottom Right (Rounded) - Tangent Arc
                path.addArc(tangent1End: CGPoint(x: rect.width, y: rect.height), tangent2End: CGPoint(x: rect.width, y: rect.height - cornerRadius), radius: cornerRadius)
                
                // Top Right (Rounded) - Tangent Arc - Closing loop
                path.addArc(tangent1End: CGPoint(x: rect.width, y: 0), tangent2End: CGPoint(x: rect.width - cornerRadius, y: 0), radius: cornerRadius)
                path.closeSubpath()
            }
            
            return path
        }
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

    private func infoItem(label: String, value: String, valueColor: Color = .white, isBold: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.custom("HelveticaNeue-Medium", size: 8))
                .foregroundStyle(.white.opacity(0.6)) // Increased contrast (0.4 -> 0.6)
            Text(value)
                .font(.custom(isBold ? "HelveticaNeue-Bold" : "HelveticaNeue-Bold", size: 12)) // keeping bold base, but logic ready for weight change if needed
                .foregroundStyle(valueColor)
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
        formatter.locale = Locale(identifier: "en_GB") // Ensure consistency
        formatter.dateFormat = "dd MMM"
        return formatter.string(from: date).uppercased()
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
