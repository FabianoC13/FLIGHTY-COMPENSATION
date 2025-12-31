import SwiftUI

struct WalletPassView: View {
    let flight: Flight
    // In a real app, we would parse this from the scanned boarding pass string.
    // For now, we mock the specific boarding info (Seat, Gate, Zone) as it's not in our Flight model yet.
    var seat: String = "4A"
    var gate: String = "B22"
    var zone: String = "1"
    
    var body: some View {
        VStack(spacing: 0) {
            // --- HEADER (Airline Color) ---
            VStack {
                HStack {
                    // Logo Placeholder
                    Circle()
                        .fill(Color.white)
                        .frame(width: 32, height: 32)
                        .overlay(Text(flight.airline.code).font(.caption).bold())
                    
                    Text(flight.airline.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding()
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading) {
                        Text(flight.departureAirport.code)
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.white)
                        Text(flight.departureAirport.city)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "airplane")
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 10)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(flight.arrivalAirport.code)
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.white)
                        Text(flight.arrivalAirport.city)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // --- BODY (Details) ---
            VStack(spacing: 20) {
                HStack {
                    DetailColumn(label: "FLIGHT", value: flight.displayFlightNumber)
                    Spacer()
                    DetailColumn(label: "GATE", value: gate)
                    Spacer()
                    DetailColumn(label: "ZONE", value: zone)
                    Spacer()
                    DetailColumn(label: "SEAT", value: seat)
                }
                .padding(.top, 20)
                
                HStack {
                    DetailColumn(label: "DATE", value: flight.scheduledDeparture.formatted(date: .numeric, time: .omitted))
                    Spacer()
                    DetailColumn(label: "BOARDING", value: flight.scheduledDeparture.addingTimeInterval(-1800).formatted(date: .omitted, time: .shortened))
                }
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // Barcode Area
                VStack(spacing: 5) {
                    Image(systemName: "qrcode")
                        .resizable()
                        .colorMultiply(.primary) // Auto dark/light mode
                        .frame(width: 120, height: 120)
                    
                    Text("Scanned from Boarding Pass")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)
            }
            .padding(.horizontal)
            .background(Color("CardBackground")) // Requires asset or system color
            .background(Color(.systemBackground))
            .cornerRadius(16) // Bottom corners
            .offset(y: -10) // Overlap effect
        }
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding()
    }
}

struct DetailColumn: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .fontWeight(.bold)
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()
        WalletPassView(flight: Flight.demoFlights[0])
    }
}
