import FirebaseFirestore
import FirebaseAuth

protocol FlightStorageServiceProtocol {
    func save(flights: [Flight])
    func load() -> [Flight]
    func fetchFlights() async throws -> [Flight]
}

final class FlightStorageService: FlightStorageServiceProtocol {
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    // MARK: - Local File Ops
    private let fileManager = FileManager.default
    private let fileName = "saved_flights.json"
    
    private var fileURL: URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    private func saveLocally(flights: [Flight]) {
        guard let fileURL = fileURL else { return }
        do {
            let data = try JSONEncoder().encode(flights)
            try data.write(to: fileURL)
            print("💾 Saved \(flights.count) flights to disk.")
        } catch {
            print("❌ Error saving flights locally: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Protocol Implementation
    
    func save(flights: [Flight]) {
        // 1. Save locally (Source of Truth for immediate UI)
        saveLocally(flights: flights)
        
        // 2. Sync to Cloud
        syncToCloud(flights: flights)
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
    
    func fetchFlights() async throws -> [Flight] {
        // Ensure user is signed in
        if auth.currentUser == nil {
            try await auth.signInAnonymously()
        }
        
        guard let userId = auth.currentUser?.uid else { return load() }
        
        print("☁️ Fetching flights for user: \(userId)")
        let snapshot = try await db.collection("users").document(userId).collection("flights").getDocuments()
        
        if snapshot.documents.isEmpty {
            print("☁️ No flights in cloud. Using local.")
            return load()
        }
        
        let cloudFlights = snapshot.documents.compactMap { doc -> Flight? in
             try? doc.data(as: Flight.self)
        }
        
        print("☁️ Fetched \(cloudFlights.count) flights from Cloud.")
        
        // Update local cache
        saveLocally(flights: cloudFlights)
        return cloudFlights
    }
    
    // MARK: - Private Helpers
    
    private func syncToCloud(flights: [Flight]) {
        guard let userId = auth.currentUser?.uid else { return }
        
        let batch = db.batch()
        let collectionRef = db.collection("users").document(userId).collection("flights")
        
        for flight in flights {
            let docRef = collectionRef.document(flight.id.uuidString)
            _ = try? batch.setData(from: flight, forDocument: docRef)
        }
        
        // Note: Real sync needs deletion handling, but for now we Overwrite/Add.
        // We're not handling deletions from cloud in this simplified sync.
        
        batch.commit { error in
            if let error = error {
                print("❌ Cloud Sync Error: \(error.localizedDescription)")
            } else {
                print("✅ Synced \(flights.count) flights to Cloud.")
            }
        }
    }
}
