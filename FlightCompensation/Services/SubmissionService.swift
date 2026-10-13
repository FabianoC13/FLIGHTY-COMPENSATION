import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Response from the backend after a successful claim submission
struct ClaimSubmissionResponse: Codable {
    let success: Bool
    let claimReference: String
    let message: String
}

/// Everything needed to file one claim.
struct ClaimSubmission {
    struct File {
        /// Key in the claim's `documents` map, e.g. "authorization", "airlineLetter", "idDocument".
        let key: String
        let fileName: String
        let contentType: String
        let data: Data
    }

    let claimReference: String
    let claimType: String          // "airline" | "aesa"
    let isTest: Bool
    /// Firestore fields other than userId/status/documents (flight, passenger, disruption, eligibility, signature…).
    let fields: [String: Any]
    let files: [File]
}

enum SubmissionError: LocalizedError {
    case notSignedIn
    case anonymousAccount

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "You need to be signed in to submit a claim."
        case .anonymousAccount:
            return "Sign in with Apple or Google (Settings → Profile) before submitting, so we can contact you about your claim and verify your signature."
        }
    }
}

protocol SubmissionServiceProtocol {
    func submitClaim(_ submission: ClaimSubmission) async throws -> ClaimSubmissionResponse
}

enum ClaimReference {
    /// e.g. FC-7K3QX9M2PA. Unambiguous characters, ~50 bits of randomness.
    static func generate() -> String {
        let alphabet = Array("ABCDEFGHJKMNPQRSTVWXYZ23456789")
        var generator = SystemRandomNumberGenerator()
        let suffix = String((0..<10).map { _ in alphabet[Int(generator.next(upperBound: UInt(alphabet.count)))] })
        return "FC-\(suffix)"
    }
}

/// Uploads the files to Storage, then creates `claims/{reference}`.
/// The `onClaimCreated` Cloud Function takes it from there (emails airline, passenger and ops).
final class FirestoreSubmissionService: SubmissionServiceProtocol {

    func submitClaim(_ submission: ClaimSubmission) async throws -> ClaimSubmissionResponse {
        guard let user = Auth.auth().currentUser else { throw SubmissionError.notSignedIn }
        #if !DEBUG
        if user.isAnonymous { throw SubmissionError.anonymousAccount }
        #endif

        var documents: [String: String] = [:]
        for file in submission.files {
            documents[file.key] = try await ClaimDocumentService.shared.upload(
                data: file.data,
                contentType: file.contentType,
                userId: user.uid,
                claimReference: submission.claimReference,
                fileName: file.fileName
            )
        }

        var data = submission.fields
        data["userId"] = user.uid
        data["claimReference"] = submission.claimReference
        data["status"] = "submitted"
        data["claimType"] = submission.claimType
        data["isTest"] = submission.isTest
        data["documents"] = documents
        data["appVersion"] = Config.appVersion
        data["createdAt"] = FieldValue.serverTimestamp()

        try await Firestore.firestore().collection("claims").document(submission.claimReference).setData(data)

        return ClaimSubmissionResponse(success: true, claimReference: submission.claimReference, message: "Claim submitted.")
    }
}

/// Offline stand-in for previews and UI tests.
final class MockSubmissionService: SubmissionServiceProtocol {
    func submitClaim(_ submission: ClaimSubmission) async throws -> ClaimSubmissionResponse {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return ClaimSubmissionResponse(success: true, claimReference: submission.claimReference, message: "Claim registered (mock).")
    }
}
