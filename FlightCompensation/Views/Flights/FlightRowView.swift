import SwiftUI

/// Clean flight row view matching the modern design
struct FlightRowView: View {
    let flight: Flight
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isSwiped = false
    
    private var statusText: String {
        switch flight.currentStatus {
        case .onTime, .scheduled:
            return "Departs On Time"
        case .delayed:
            return "Delayed"
        case .cancelled:
            return "Cancelled"
        case .departed:
            return "Departed"
        case .arrived:
            return "Arrived"
        }
    }
    
    private var statusColor: Color {
        switch flight.currentStatus {
        case .onTime, .scheduled, .departed, .arrived:
            return Color(hex: "34C759") // Green
        case .delayed:
            return Color(hex: "FF9500") // Amber/Orange
        case .cancelled:
            return Color(hex: "FF3B30") // Red
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
    
    var body: some View {
        ZStack {
            // Background Delete Button
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    Button(action: {
                        HapticsManager.shared.notification(type: .warning)
                        withAnimation(.spring()) {
                            offset = -500
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
            }
            
            // Main Row Content
            Button(action: {
                if isSwiped {
                    withAnimation(.spring()) {
                        offset = 0
                        isSwiped = false
                    }
                } else {
                    HapticsManager.shared.selection()
                    onTap()
                }
            }) {
                HStack(spacing: 16) {
                    // Airline Logo
                    airlineLogo
                    
                    // Flight Info
                    VStack(alignment: .leading, spacing: 8) {
                        // Flight Number and Status
                        HStack {
                            Text(flight.displayFlightNumber)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text(statusText)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(statusColor)
                        }
                        
                        // Route (City names)
                        Text("\(flight.departureAirport.city) to \(flight.arrivalAirport.city)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Times Row
                        HStack(spacing: 24) {
                            // Departure
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(statusColor)
                                
                                Text(flight.departureAirport.code)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(statusColor)
                                
                                Text(timeFormatter.string(from: flight.scheduledDeparture))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(statusColor)
                            }
                            
                            // Arrival
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(statusColor)
                                
                                Text(flight.arrivalAirport.code)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(statusColor)
                                
                                Text(timeFormatter.string(from: flight.scheduledArrival))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(statusColor)
                            }
                            
                            Spacer()
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.12, green: 0.13, blue: 0.18))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
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
        }
    }
    
    @ViewBuilder
    private var airlineLogo: some View {
        // Airline logo with brand styling
        ZStack {
            Circle()
                .fill(flight.airline.brandColor)
                .frame(width: 44, height: 44)
            
            Text(airlineLogoText)
                .font(.custom("HelveticaNeue-Bold", size: logoFontSize))
                .italic()
                .foregroundColor(flight.airline.brandContentColor)
        }
    }
    
    private var airlineLogoText: String {
        // Use stylized text for known airlines
        switch flight.airline.code.uppercased() {
        case "UX", "AEA": // Air Europa
            return "æ"
        case "IB", "IBE": // Iberia
            return "IB"
        case "VY", "VLG": // Vueling
            return "VY"
        case "FR", "RYR": // Ryanair
            return "FR"
        case "BA", "BAW": // British Airways
            return "BA"
        case "LH", "DLH": // Lufthansa
            return "LH"
        case "AF", "AFR": // Air France
            return "AF"
        case "KL", "KLM": // KLM
            return "KL"
        default:
            return flight.airline.code.prefix(2).uppercased()
        }
    }
    
    private var logoFontSize: CGFloat {
        switch flight.airline.code.uppercased() {
        case "UX", "AEA":
            return 28 // Larger for stylized symbol
        default:
            return 14
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 16) {
            FlightRowView(
                flight: Flight(
                    flightNumber: "1509",
                    airline: Airline(code: "UX", name: "Air Europa"),
                    departureAirport: Airport(code: "MAD", name: "Madrid-Barajas", city: "Madrid", country: "Spain"),
                    arrivalAirport: Airport(code: "FRA", name: "Frankfurt Airport", city: "Frankfurt", country: "Germany"),
                    scheduledDeparture: Date(),
                    scheduledArrival: Date().addingTimeInterval(7200),
                    currentStatus: .onTime
                ),
                onTap: {},
                onDelete: {}
            )
            
            FlightRowView(
                flight: Flight(
                    flightNumber: "001",
                    airline: Airline(code: "CA", name: "Test Airline"),
                    departureAirport: Airport(code: "MAD", name: "Madrid-Barajas", city: "Madrid", country: "Spain"),
                    arrivalAirport: Airport(code: "CDG", name: "Charles de Gaulle", city: "Paris", country: "France"),
                    scheduledDeparture: Date(),
                    scheduledArrival: Date().addingTimeInterval(7200),
                    currentStatus: .cancelled
                ),
                onTap: {},
                onDelete: {}
            )
        }
        .padding()
    }
}
