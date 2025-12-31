import SwiftUI

struct FlightCardView: View {
    let flight: Flight
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 20) {
                // Airline Logo / Placeholder
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(flight.airline.code)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(PremiumTheme.electricBlue)
                    )
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(flight.route)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "airplane")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                            
                        Text(flight.airline.name)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    Text("#\(flight.displayFlightNumber)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(PremiumTheme.electricBlue.opacity(0.8))
                }
                
                Spacer()
                
                // Status badge
                // Status badges
                VStack(alignment: .trailing, spacing: 8) {
                    StatusBadge(status: flight.currentStatus)
                    
                    if flight.claimStatus != .notStarted {
                        ClaimStatusBadge(status: flight.claimStatus)
                    }
                }
            }
            .padding(20)
            .glassCard(cornerRadius: 24)
        }
        .buttonStyle(PlainButtonStyle())
        .transition(.opacity.combined(with: .move(edge: .leading)))
        .animation(.easeInOut(duration: 0.3), value: flight.currentStatus)
    }
}

struct ClaimStatusBadge: View {
    let status: ClaimStatus
    
    var body: some View {
        Text(status.rawValue.uppercased())
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color(hex: status.colorHex))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color(hex: status.colorHex).opacity(0.3), radius: 4)
    }
}

struct StatusBadge: View {
    let status: FlightStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color(hex: status.colorHex).opacity(0.8))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color(hex: status.colorHex).opacity(0.4), radius: 5)
    }
}
