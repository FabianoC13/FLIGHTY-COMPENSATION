import Foundation

enum ClaimDocumentType {
    case masterAuthorization
    case airlineComplaint
    
    var folderName: String {
        switch self {
        case .masterAuthorization: return "Legal_Authorizations"
        case .airlineComplaint: return "Airline_Complaints"
        }
    }
    
    func filename(for reference: String) -> String {
        let safeRef = reference.replacingOccurrences(of: "/", with: "-")
        switch self {
        case .masterAuthorization: return "MasterAuth_\(safeRef).pdf"
        case .airlineComplaint: return "Complaint_\(safeRef).pdf"
        }
    }
}

struct ClaimDocumentService {
    static let shared = ClaimDocumentService()
    
    private let fileManager = FileManager.default
    
    private func getDirectory(for type: ClaimDocumentType) -> URL? {
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let mainDir = documents.appendingPathComponent("FlightyClaims", isDirectory: true)
        let subDir = mainDir.appendingPathComponent(type.folderName, isDirectory: true)
        
        if !fileManager.fileExists(atPath: subDir.path) {
            try? fileManager.createDirectory(at: subDir, withIntermediateDirectories: true, attributes: nil)
        }
        return subDir
    }
    
    func savePDF(data: Data, claimReference: String, type: ClaimDocumentType) -> URL? {
        guard let dir = getDirectory(for: type) else { return nil }
        let filename = type.filename(for: claimReference)
        let url = dir.appendingPathComponent(filename)
        
        do {
            try data.write(to: url)
            
            #if targetEnvironment(simulator)
            saveToMacDocuments(data: data, filename: filename, subfolder: type.folderName)
            #endif
            
            return url
        } catch {
            print("Failed to save PDF: \(error)")
            return nil
        }
    }
    
    #if targetEnvironment(simulator)
    private func saveToMacDocuments(data: Data, filename: String, subfolder: String) {
        // Hardcoded path for this specific user/machine environment
        let macDocsPath = "/Users/fabiano/Documents/FlightyClaims/\(subfolder)"
        let macDocsURL = URL(fileURLWithPath: macDocsPath)
        
        do {
            if !FileManager.default.fileExists(atPath: macDocsPath) {
                try FileManager.default.createDirectory(at: macDocsURL, withIntermediateDirectories: true)
            }
            
            let destinationURL = macDocsURL.appendingPathComponent(filename)
            try data.write(to: destinationURL)
            print("💻 Saved copy to Mac: \(destinationURL.path)")
        } catch {
            print("⚠️ Failed to save to Mac Documents: \(error)")
        }
    }
    #endif
    
    func getPDFURL(for claimReference: String, type: ClaimDocumentType) -> URL? {
        guard let dir = getDirectory(for: type) else { return nil }
        let filename = type.filename(for: claimReference)
        let url = dir.appendingPathComponent(filename)
        
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }
}
