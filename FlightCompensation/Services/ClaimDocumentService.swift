import Foundation
import FirebaseStorage

enum ClaimDocumentType {
    /// Signed authorisation: service agreement, assignment of claim, power of attorney.
    case masterAuthorization
    /// Letter to the airline.
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
        case .masterAuthorization: return "Authorization_\(safeRef).pdf"
        case .airlineComplaint: return "ClaimLetter_\(safeRef).pdf"
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
            try? fileManager.createDirectory(at: subDir, withIntermediateDirectories: true, attributes: [
                .protectionKey: FileProtectionType.complete
            ])
        }
        return subDir
    }

    /// Keeps a copy on the device so the passenger can open and share what they signed.
    @discardableResult
    func savePDF(data: Data, claimReference: String, type: ClaimDocumentType) -> URL? {
        guard let dir = getDirectory(for: type) else { return nil }
        let url = dir.appendingPathComponent(type.filename(for: claimReference))
        do {
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            return url
        } catch {
            print("Failed to save PDF: \(error)")
            return nil
        }
    }

    func getPDFURL(for claimReference: String, type: ClaimDocumentType) -> URL? {
        guard let dir = getDirectory(for: type) else { return nil }
        let url = dir.appendingPathComponent(type.filename(for: claimReference))
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    /// Uploads a claim file to `claims/{uid}/{claimReference}/{fileName}` (see storage.rules)
    /// and returns its Storage path.
    func upload(data: Data, contentType: String, userId: String, claimReference: String, fileName: String) async throws -> String {
        let path = "claims/\(userId)/\(claimReference)/\(fileName)"
        let metadata = StorageMetadata()
        metadata.contentType = contentType
        _ = try await Storage.storage().reference().child(path).putDataAsync(data, metadata: metadata)
        return path
    }
}
