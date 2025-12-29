import Foundation

extension Flight {
    static var demoFlights: [Flight] {
        let calendar = Calendar.current
        let today = Date()
        
        func date(dayOffset: Int, hour: Int, minute: Int) -> Date {
            let baseDate = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: baseDate) ?? baseDate
        }
        
        func buildFlight(
            airlineCode: String,
            airlineName: String,
            flightNumber: String,
            departure: Airport,
            arrival: Airport,
            departureDayOffset: Int,
            departureHour: Int,
            departureMinute: Int,
            durationHours: Int,
            status: FlightStatus,
            delayHours: Double? = nil
        ) -> Flight {
            let scheduledDeparture = date(dayOffset: departureDayOffset, hour: departureHour, minute: departureMinute)
            let scheduledArrival = calendar.date(byAdding: .hour, value: durationHours, to: scheduledDeparture) ?? scheduledDeparture
            var delayEvents: [DelayEvent] = []
            
            if let delayHours {
                delayEvents = [
                    DelayEvent(
                        type: status == .cancelled ? .cancellation : .delay,
                        duration: delayHours * 3600.0,
                        actualTime: status == .cancelled ? nil : Date(),
                        reason: status == .cancelled ? "Flight cancelled by airline" : "Operational delay"
                    )
                ]
            }
            
            return Flight(
                flightNumber: flightNumber,
                airline: Airline(code: airlineCode, name: airlineName),
                departureAirport: departure,
                arrivalAirport: arrival,
                scheduledDeparture: scheduledDeparture,
                scheduledArrival: scheduledArrival,
                status: status,
                currentStatus: status,
                delayEvents: delayEvents
            )
        }
        
        let lhr = Airport(code: "LHR", name: "Heathrow Airport", city: "London", country: "UK")
        let cdg = Airport(code: "CDG", name: "Charles de Gaulle Airport", city: "Paris", country: "France")
        let fra = Airport(code: "FRA", name: "Frankfurt Airport", city: "Frankfurt", country: "Germany")
        let ams = Airport(code: "AMS", name: "Amsterdam Airport Schiphol", city: "Amsterdam", country: "Netherlands")
        let mad = Airport(code: "MAD", name: "Adolfo Suárez Madrid–Barajas Airport", city: "Madrid", country: "Spain")
        let bcn = Airport(code: "BCN", name: "Barcelona–El Prat Airport", city: "Barcelona", country: "Spain")
        let fco = Airport(code: "FCO", name: "Leonardo da Vinci–Fiumicino Airport", city: "Rome", country: "Italy")
        
        let jfk = Airport(code: "JFK", name: "John F. Kennedy International Airport", city: "New York", country: "USA")
        let lax = Airport(code: "LAX", name: "Los Angeles International Airport", city: "Los Angeles", country: "USA")
        let dxb = Airport(code: "DXB", name: "Dubai International Airport", city: "Dubai", country: "UAE")
        let sin = Airport(code: "SIN", name: "Singapore Changi Airport", city: "Singapore", country: "Singapore")
        let nrt = Airport(code: "NRT", name: "Narita International Airport", city: "Tokyo", country: "Japan")
        
        return [
            // EU/UK flights (5 total, 3 delayed for eligibility)
            buildFlight(airlineCode: "BA", airlineName: "British Airways", flightNumber: "101", departure: lhr, arrival: cdg, departureDayOffset: 1, departureHour: 9, departureMinute: 15, durationHours: 2, status: .delayed, delayHours: 4.0),
            buildFlight(airlineCode: "LH", airlineName: "Lufthansa", flightNumber: "202", departure: fra, arrival: ams, departureDayOffset: 1, departureHour: 11, departureMinute: 30, durationHours: 2, status: .delayed, delayHours: 3.5),
            buildFlight(airlineCode: "FR", airlineName: "Ryanair", flightNumber: "303", departure: mad, arrival: bcn, departureDayOffset: 2, departureHour: 7, departureMinute: 45, durationHours: 1, status: .delayed, delayHours: 3.0),
            buildFlight(airlineCode: "VY", airlineName: "Vueling", flightNumber: "404", departure: bcn, arrival: fco, departureDayOffset: 2, departureHour: 14, departureMinute: 20, durationHours: 2, status: .onTime),
            buildFlight(airlineCode: "KL", airlineName: "KLM", flightNumber: "505", departure: ams, arrival: cdg, departureDayOffset: 3, departureHour: 16, departureMinute: 0, durationHours: 1, status: .onTime),
            
            // Non-EU flights (5 total, delayed but not eligible due to jurisdiction)
            buildFlight(airlineCode: "DL", airlineName: "Delta Air Lines", flightNumber: "606", departure: jfk, arrival: lax, departureDayOffset: 1, departureHour: 13, departureMinute: 10, durationHours: 6, status: .delayed, delayHours: 3.5),
            buildFlight(airlineCode: "EK", airlineName: "Emirates", flightNumber: "707", departure: dxb, arrival: sin, departureDayOffset: 2, departureHour: 22, departureMinute: 5, durationHours: 7, status: .delayed, delayHours: 4.0),
            buildFlight(airlineCode: "SQ", airlineName: "Singapore Airlines", flightNumber: "808", departure: sin, arrival: nrt, departureDayOffset: 3, departureHour: 8, departureMinute: 50, durationHours: 7, status: .delayed, delayHours: 3.2),
            buildFlight(airlineCode: "UA", airlineName: "United Airlines", flightNumber: "909", departure: lax, arrival: jfk, departureDayOffset: 3, departureHour: 12, departureMinute: 40, durationHours: 5, status: .delayed, delayHours: 3.1),
            buildFlight(airlineCode: "AA", airlineName: "American Airlines", flightNumber: "1001", departure: jfk, arrival: lax, departureDayOffset: 4, departureHour: 6, departureMinute: 30, durationHours: 6, status: .delayed, delayHours: 3.8)
        ]
    }
    
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
