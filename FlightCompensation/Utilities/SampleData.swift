import Foundation

extension Flight {
    static var sampleDelayedFlight: Flight {
        let airline = Airline(code: "FR", name: "Ryanair")
        let departure = Airport(code: "MAD", name: "Adolfo Suárez Madrid–Barajas Airport", city: "Madrid", country: "Spain")
        let arrival = Airport(code: "CDG", name: "Charles de Gaulle Airport", city: "Paris", country: "France")
        
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let scheduledDeparture = Calendar.current.date(bySettingHour: 14, minute: 30, second: 0, of: tomorrow) ?? tomorrow
        let scheduledArrival = Calendar.current.date(bySettingHour: 16, minute: 45, second: 0, of: tomorrow) ?? tomorrow
        
        let delayEvent = DelayEvent(
            type: .delay,
            duration: 4 * 3600, // 4 hours
            actualTime: Calendar.current.date(byAdding: .hour, value: 4, to: scheduledArrival),
            reason: "Operational delay"
        )
        
        return Flight(
            flightNumber: "1234",
            airline: airline,
            departureAirport: departure,
            arrivalAirport: arrival,
            scheduledDeparture: scheduledDeparture,
            scheduledArrival: scheduledArrival,
            status: .delayed,
            currentStatus: .delayed,
            delayEvents: [delayEvent]
        )
    }
    
    static var sampleOnTimeFlight: Flight {
        let airline = Airline(code: "BA", name: "British Airways")
        let departure = Airport(code: "LHR", name: "Heathrow Airport", city: "London", country: "UK")
        let arrival = Airport(code: "JFK", name: "John F. Kennedy International Airport", city: "New York", country: "USA")
        
        let tomorrow = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        let scheduledDeparture = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        let scheduledArrival = Calendar.current.date(byAdding: .hour, value: 8, to: scheduledDeparture) ?? tomorrow
        
        return Flight(
            flightNumber: "178",
            airline: airline,
            departureAirport: departure,
            arrivalAirport: arrival,
            scheduledDeparture: scheduledDeparture,
            scheduledArrival: scheduledArrival,
            status: .onTime,
            currentStatus: .onTime
        )
    }
}

