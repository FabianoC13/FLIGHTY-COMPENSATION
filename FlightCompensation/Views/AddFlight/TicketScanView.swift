import SwiftUI
import VisionKit

struct TicketScanView: View {
    @ObservedObject var viewModel: AddFlightViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var isScanning = false
    @State private var scannedCode: String?
    @State private var showConfirmation = false
    @State private var scannerID = UUID() // Force reset
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    // Live Camera Scanner
                    LiveTextScanner(
                        onFlightCodeDetected: { code in
                            if scannedCode == nil {
                                scannedCode = code
                                showConfirmation = true
                            }
                        },
                        onCancel: {
                            dismiss()
                        }
                    )
                    .id(scannerID) // Forces recreation on retry
                    .ignoresSafeArea()
                    
                    // Overlay
                    VStack {
                        Text("Scan Boarding Pass")
                            .font(.headline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            .padding(.top, 40)
                        
                        Spacer()
                        
                        Text("Tap the flight number to select (e.g. BA123)")
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                            .padding(.bottom, 60)
                    }
                } else {
                    // Fallback for Simulator / Unsupported Devices
                    VStack(spacing: AppConstants.largeSpacing) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("Scanner not available")
                            .font(.title3)
                            .foregroundColor(.white)
                        
                        Text("This device or simulator does not support Live Text scanning. Please use the manual entry or simulate a scan below.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.7))
                            .padding()
                        
                        Button("Simulate Scan (BA123)") {
                            scannedCode = "BA123"
                            showConfirmation = true
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
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
            .alert("Flight Detected", isPresented: $showConfirmation) {
                Button("Add Flight") {
                    if let code = scannedCode {
                        let flight = createFlightFromCode(code)
                        viewModel.addFlightFromScan(flight)
                        dismiss()
                    }
                }
                Button("Retry", role: .cancel) {
                    scannedCode = nil
                    scannerID = UUID() // Reset scanner
                }
            } message: {
                Text("Do you want to add flight \(scannedCode ?? "")?")
            }
        }
    }
    
    private func createFlightFromCode(_ code: String) -> Flight {
        // Simple parser: Split Letters and Numbers
        // E.g. "BA123" -> "BA", "123"
        let range = code.rangeOfCharacter(from: CharacterSet.decimalDigits)
        var airlineCode = "XX"
        var number = "0000"
        
        if let range = range {
            airlineCode = String(code[..<range.lowerBound])
            number = String(code[range.lowerBound...])
        }
        
        let airline = Airline(code: airlineCode, name: "Unknown Airline")
        // Use dummy airports; tracking service will update them
        let depAirport = Airport(code: "UNK", name: "Origin", city: "Unknown", country: "")
        let arrAirport = Airport(code: "UNK", name: "Destination", city: "Unknown", country: "")
        
        // Default to today/tomorrow logic
        let now = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        
        return Flight(
            flightNumber: number,
            airline: airline,
            departureAirport: depAirport, // Will be auto-corrected by Service
            arrivalAirport: arrAirport,   // Will be auto-corrected by Service
            scheduledDeparture: tomorrow, // Default to tomorrow
            scheduledArrival: tomorrow.addingTimeInterval(3600*2)
        )
    }
}


