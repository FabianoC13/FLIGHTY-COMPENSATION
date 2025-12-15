import SwiftUI

struct ManualEntryView: View {
    @ObservedObject var viewModel: AddFlightViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var flightCode: String = ""
    @State private var selectedDate = Date()
    @FocusState private var isFlightCodeFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Flight Details") {
                    TextField("Flight Code (e.g., BA178)", text: $flightCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($isFlightCodeFocused)
                        .onAppear {
                            isFlightCodeFocused = true
                        }
                    
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                }
                
                Section {
                    Button("Add Flight") {
                        addFlight()
                    }
                    .disabled(!isValid)
                } footer: {
                    Text("Enter the full flight code: airline code + flight number (e.g., BA178, FR1234, LH441). Minimum 3 characters.")
                }
            }
            .navigationTitle("Enter Flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
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

