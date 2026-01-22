import FirebaseFirestore
import FirebaseAuth

protocol FlightStorageServiceProtocol {
    func save(flights: [Flight])
    func load() -> [Flight]
    func fetchFlights() async throws -> [Flight]
    func moveToHistory(flight: Flight) async throws
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
    
    
    func moveToHistory(flight: Flight) async throws {
        // Ensure user is signed in (so we have a stable userId namespace)
        if auth.currentUser == nil {
            try await auth.signInAnonymously()
        }
        
        // Always update local cache immediately, even if cloud auth isn't available
        // (keeps UI + disk in sync with the user's action).
        var currentFlights = load()
        currentFlights.removeAll { $0.id == flight.id }
        saveLocally(flights: currentFlights)
        
        // If we still don't have a user, we can't sync to Firestore.
        guard let userId = auth.currentUser?.uid else {
            print("⚠️ No authenticated user. Skipping cloud moveToHistory; local cache updated.")
            return
        }
        
        let flightRef = db.collection("users").document(userId).collection("flights").document(flight.id.uuidString)
        let historyRef = db.collection("users").document(userId).collection("history").document(flight.id.uuidString)
        
        // Use a transaction to move the document
        try await db.runTransaction { (transaction, errorPointer) -> Any? in
            // 1. Write to history
            do {
                try transaction.setData(from: flight, forDocument: historyRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            
            // 2. Delete from active flights
            transaction.deleteDocument(flightRef)
            
            return nil
        }
        
        print("✅ Moved flight \(flight.id) to history in cloud.")
    }

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
