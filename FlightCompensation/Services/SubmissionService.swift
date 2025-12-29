import Foundation

/// Response from the backend after a successful claim submission
struct ClaimSubmissionResponse: Codable {
    let success: Bool
    let claimReference: String
    let message: String
}

protocol SubmissionServiceProtocol {
    func submitClaim(request: ClaimRequest, pdfData: Data) async throws -> ClaimSubmissionResponse
}

/// Simulation of a backend service that accepts claims
final class MockSubmissionService: SubmissionServiceProtocol {
    
    func submitClaim(request: ClaimRequest, pdfData: Data) async throws -> ClaimSubmissionResponse {
        // Simulate network latency (2-4 seconds)
        let latency = UInt64(Float.random(in: 2.0...4.0) * 1_000_000_000)
        try await Task.sleep(nanoseconds: latency)
        
        // Randomly simulate failure (5% chance) just for robustness testing
        // if Int.random(in: 1...20) == 1 {
        //    throw NSError(domain: "SubmissionService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server overloaded. Please try again."])
        // }
        
        // Generate a fake claim reference
        let year = Calendar.current.component(.year, from: Date())
        let randomNum = Int.random(in: 1000...9999)
        let reference = "AESA-\(year)-\(randomNum)"
        
        // Save the PDF locally for the user
        _ = ClaimDocumentService.shared.savePDF(data: pdfData, claimReference: reference, type: .masterAuthorization)
        
        return ClaimSubmissionResponse(
            success: true,
            claimReference: reference,
            message: "Claim successfully registered."
        )
    }
}
