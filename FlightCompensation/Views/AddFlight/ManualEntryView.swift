import SwiftUI

struct ManualEntryView: View {
    @ObservedObject var viewModel: AddFlightViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var flightCode: String = ""
    @State private var selectedDate = Date()
    @FocusState private var isFlightCodeFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark gradient background matching AddFlightView
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.07, blue: 0.14),
                        Color(red: 0.02, green: 0.02, blue: 0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                Form {
                    Section {
                        // Custom styled text field
                        TextField("Flight Code (e.g., BA178)", text: $flightCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .focused($isFlightCodeFocused)
                            .listRowBackground(Color.white.opacity(0.1))
                            .foregroundStyle(.white)
                        
                        DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                            .listRowBackground(Color.white.opacity(0.1))
                            .colorScheme(.dark) // Ensure date picker text is white
                    } header: {
                        Text("Flight Details")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Section {
                        Button(action: {
                            addFlight()
                        }) {
                            Text("Add Flight")
                                .frame(maxWidth: .infinity)
                                .bold()
                        }
                        .disabled(!isValid)
                        .listRowBackground(
                            Group {
                                if isValid {
                                    PremiumTheme.primaryGradient
                                } else {
                                    Color.white.opacity(0.1)
                                }
                            }
                        )
                        .foregroundStyle(isValid ? .white : .white.opacity(0.3))
                    } footer: {
                        Text("Enter the full flight code: airline code + flight number (e.g., BA178, FR1234, LH441). Minimum 3 characters.")
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Enter Flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
    
    private var isValid: Bool {
        !flightCode.trimmingCharacters(in: .whitespaces).isEmpty &&
        flightCode.count >= 3
    }
    
    private func addFlight() {
        let trimmedCode = flightCode.uppercased().trimmingCharacters(in: .whitespaces)
        
        // Extract airline code (first 2-3 letters) and flight number
        // Handle codes like: BA178, FR1234, A320, etc.
        let (airlineCode, flightNumber) = parseFlightCode(trimmedCode)
        
        let airline = Airline(
            code: airlineCode,
            name: airlineCode // Will be updated when we get real data from API
        )
        
        // Use placeholder airports - these will be updated when we get real flight data
        // For now, we'll use generic airports since we don't have route info yet
        // Seed test data for DELAY*/CANCEL* codes so UI shows immediate values
        let trimmed = flightCode.uppercased().trimmingCharacters(in: .whitespaces)
        if trimmed.starts(with: "DELAY") || trimmed.starts(with: "CANCEL") {
            let depAirport = Airport(
                id: UUID(uuidString: "12345678-1234-1234-1234-123456789001") ?? UUID(),
                code: "MAD",
                name: "Adolfo Suárez Madrid–Barajas Airport",
                city: "Madrid",
                country: "Spain"
            )
            
            let arrAirport = Airport(
                id: UUID(uuidString: "12345678-1234-1234-1234-123456789002") ?? UUID(),
                code: "CDG",
                name: "Charles de Gaulle Airport",
                city: "Paris",
                country: "France"
            )
            
            let scheduledDeparture = Calendar.current.date(bySettingHour: 14, minute: 30, second: 0, of: selectedDate) ?? selectedDate
            let scheduledArrival = Calendar.current.date(byAdding: .hour, value: 2, to: scheduledDeparture) ?? scheduledDeparture

            var status: FlightStatus = .scheduled
            var currentStatus: FlightStatus = .scheduled
            var delayEvents: [DelayEvent] = []

            if trimmed.starts(with: "DELAY") {
                status = .delayed
                currentStatus = .delayed
                delayEvents = [DelayEvent(type: .delay, duration: 4 * 3600, actualTime: Calendar.current.date(byAdding: .hour, value: 4, to: scheduledArrival), reason: "Simulated test delay")]
            } else if trimmed.starts(with: "CANCEL") {
                status = .cancelled
                currentStatus = .cancelled
                delayEvents = [DelayEvent(type: .cancellation, duration: 0, actualTime: nil, reason: "Simulated cancellation")]
            }

            let flight = Flight(
                flightNumber: flightNumber,
                airline: airline,
                departureAirport: depAirport,
                arrivalAirport: arrAirport,
                scheduledDeparture: scheduledDeparture,
                scheduledArrival: scheduledArrival,
                status: status,
                currentStatus: currentStatus,
                delayEvents: delayEvents
            )

            viewModel.addFlightManually(flight)
            dismiss()
            return
        }

        let depAirport = Airport(
            code: "TBD",
            name: "To be determined",
            city: "TBD",
            country: ""
        )
        
        let arrAirport = Airport(
            code: "TBD",
            name: "To be determined",
            city: "TBD",
            country: ""
        )
        
        // Default times - will be updated when tracking the flight
        let calendar = Calendar.current
        let scheduledDeparture = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        let scheduledArrival = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: selectedDate) ?? calendar.date(byAdding: .hour, value: 2, to: scheduledDeparture) ?? scheduledDeparture
        
        let flight = Flight(
            flightNumber: flightNumber,
            airline: airline,
            departureAirport: depAirport,
            arrivalAirport: arrAirport,
            scheduledDeparture: scheduledDeparture,
            scheduledArrival: scheduledArrival
        )
        
        viewModel.addFlightManually(flight)
        dismiss()
    }
    
    private func parseFlightCode(_ code: String) -> (airlineCode: String, flightNumber: String) {
        // Try to parse flight code like BA178, FR1234, A320, etc.
        // Airlines typically have 2-3 letter codes followed by numbers
        
        // Use regex to match airline code (2-3 letters) followed by numbers
        let pattern = "^([A-Z]{2,3})(\\d+)$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: code, options: [], range: NSRange(location: 0, length: code.utf16.count)),
              match.numberOfRanges >= 3 else {
            // Fallback: try simple split at first digit
            for (index, char) in code.enumerated() {
                if char.isNumber {
                    let airlineCode = String(code.prefix(index))
                    let flightNumber = String(code.dropFirst(index))
                    if airlineCode.count >= 2 && airlineCode.count <= 3 && !flightNumber.isEmpty {
                        return (airlineCode, flightNumber)
                    }
                }
            }
            
            // Last resort: assume first 2 characters are airline code
            if code.count >= 3 {
                let airlineCode = String(code.prefix(2))
                let flightNumber = String(code.dropFirst(2))
                return (airlineCode, flightNumber)
            }
            
            return ("XX", code)
        }
        
        let airlineRange = Range(match.range(at: 1), in: code)!
        let numberRange = Range(match.range(at: 2), in: code)!
        
        let airlineCode = String(code[airlineRange])
        let flightNumber = String(code[numberRange])
        
        return (airlineCode, flightNumber)
    }
}

