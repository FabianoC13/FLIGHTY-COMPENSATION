import Foundation
import FirebaseStorage

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
        guard let dir = getDirectory(for: type) else { 
            print("❌ [Documents] Could not get directory for \(type)")
            return nil 
        }
        let filename = type.filename(for: claimReference)
        let url = dir.appendingPathComponent(filename)
        
        let exists = fileManager.fileExists(atPath: url.path)
        print("📄 [Documents] Looking for: \(url.path)")
        print("📄 [Documents] File exists: \(exists)")
        
        if exists {
            // Check file size
            if let attrs = try? fileManager.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? Int {
                print("📄 [Documents] File size: \(size) bytes")
            }
        }
        
        return exists ? url : nil
    }
    
    #if targetEnvironment(simulator)
    /// Save email metadata for the local email bot to pick up
    func saveEmailMetadata(
        claimReference: String,
        toEmail: String,
        ccEmail: String?,
        subject: String,
        body: String,
        pdfFilenames: [String]
    ) {
        let macDocsPath = "/Users/fabiano/Documents/FlightyClaims/OutgoingEmails"
        let macDocsURL = URL(fileURLWithPath: macDocsPath)
        
        do {
            if !FileManager.default.fileExists(atPath: macDocsPath) {
                try FileManager.default.createDirectory(at: macDocsURL, withIntermediateDirectories: true)
            }
            
            let metadata: [String: Any] = [
                "claimReference": claimReference,
                "to": toEmail,
                "cc": ccEmail ?? "",
                "subject": subject,
                "body": body,
                "attachments": pdfFilenames,
                "status": "pending",
                "createdAt": ISO8601DateFormatter().string(from: Date())
            ]
            
            let safeRef = claimReference.replacingOccurrences(of: "/", with: "-")
            let jsonFilename = "email_\(safeRef).json"
            let jsonURL = macDocsURL.appendingPathComponent(jsonFilename)
            
            let jsonData = try JSONSerialization.data(withJSONObject: metadata, options: [.prettyPrinted, .sortedKeys])
            try jsonData.write(to: jsonURL)
            
            print("📧 Saved email metadata: \(jsonURL.path)")
        } catch {
            print("⚠️ Failed to save email metadata: \(error)")
        }
    }
    #endif
    
    /// Uploads a PDF to Firebase Storage and returns the download URL
    func uploadPDF(data: Data, claimReference: String, type: ClaimDocumentType) async -> String? {
        let storage = Storage.storage()
        let filename = type.filename(for: claimReference)
        let path = "claims/\(claimReference)/\(filename)"
        let storageRef = storage.reference().child(path)
        
        let metadata = StorageMetadata()
        metadata.contentType = "application/pdf"
        
        do {
            // Upload data
            _ = try await storageRef.putDataAsync(data, metadata: metadata)
            
            // Get download URL
            let downloadURL = try await storageRef.downloadURL()
            print("✅ Uploaded PDF to Cloud: \(path)")
            return downloadURL.absoluteString
        } catch {
            print("❌ Failed to upload PDF to Firebase Storage: \(error.localizedDescription)")
            return nil
        }
    }
}
