import Foundation

protocol FlightStorageServiceProtocol {
    func save(flights: [Flight])
    func load() -> [Flight]
}

final class FlightStorageService: FlightStorageServiceProtocol {
    private let fileManager = FileManager.default
    private let fileName = "saved_flights.json"
    
    private var fileURL: URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    func save(flights: [Flight]) {
        guard let fileURL = fileURL else { return }
        
        do {
            let data = try JSONEncoder().encode(flights)
            try data.write(to: fileURL)
            print("💾 Saved \(flights.count) flights to disk.")
        } catch {
            print("❌ Error saving flights: \(error.localizedDescription)")
        }
    }
    
    func load() -> [Flight] {
        guard let fileURL = fileURL, fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let flights = try JSONDecoder().decode([Flight].self, from: data)
            print("📂 Loaded \(flights.count) flights from disk.")
            return flights
        } catch {
            print("❌ Error loading flights: \(error.localizedDescription)")
            return []
        }
    }
}
