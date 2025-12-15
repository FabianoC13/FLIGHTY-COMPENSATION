import SwiftUI

struct TicketScanView: View {
    @ObservedObject var viewModel: AddFlightViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var isScanning = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: AppConstants.largeSpacing) {
                    Text("Scan your boarding pass")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Position your ticket within the frame")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppConstants.spacing)
                    
                    // Camera view placeholder
                    RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius)
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        .frame(height: 400)
                        .overlay(
                            VStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white.opacity(0.5))
                                Text("Camera view")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.top, 8)
                            }
                        )
                        .padding(.horizontal, AppConstants.spacing)
                    
                    Button(action: {
                        // In a real app, this would trigger OCR scanning
                        // For now, create a mock flight
                        let mockFlight = createMockFlightFromScan()
                        viewModel.addFlightFromScan(mockFlight)
                        dismiss()
                    }) {
                        Text("Capture")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor)
                            .cornerRadius(AppConstants.cardCornerRadius)
                    }
                    .padding(.horizontal, AppConstants.spacing)
                }
                .padding(.vertical, AppConstants.largeSpacing)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func createMockFlightFromScan() -> Flight {
        // Mock flight data - in real app, this would come from OCR
        let airline = Airline(code: "BA", name: "British Airways")
        let depAirport = Airport(code: "LHR", name: "Heathrow Airport", city: "London", country: "UK")
        let arrAirport = Airport(code: "CDG", name: "Charles de Gaulle Airport", city: "Paris", country: "France")
        
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let scheduledDeparture = Calendar.current.date(bySettingHour: 14, minute: 30, second: 0, of: tomorrow) ?? tomorrow
        var dateComponents = DateComponents()
        dateComponents.hour = 1
        dateComponents.minute = 30
        let scheduledArrival = Calendar.current.date(byAdding: dateComponents, to: scheduledDeparture) ?? scheduledDeparture
        
        return Flight(
            flightNumber: "123",
            airline: airline,
            departureAirport: depAirport,
            arrivalAirport: arrAirport,
            scheduledDeparture: scheduledDeparture,
            scheduledArrival: scheduledArrival
        )
    }
}


