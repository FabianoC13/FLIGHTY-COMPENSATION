import Foundation
import FirebaseFirestore

/// Service to send email requests via Firestore (Trigger Email extension)
struct EmailService {
    static let shared = EmailService()
    private let db = Firestore.firestore()
    
    struct EmailAttachment {
        let filename: String
        let data: Data
    }
    
    /// Send an email by creating a document in the 'mail' collection
    func sendEmail(
        to: String,
        cc: String? = nil,
        subject: String,
        body: String,
        attachments: [EmailAttachment] = [],
        customDocId: String? = nil,
        type: String? = nil,
        claimReference: String? = nil
    ) async -> Bool {
        do {
            var mailData: [String: Any] = [
                "to": [to],
                "message": [
                    "subject": subject,
                    "text": body,
                    "attachments": attachments.map { attachment in
                        [
                            "filename": attachment.filename,
                            "content": attachment.data.base64EncodedString()
                        ]
                    }
                ],
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            if let cc = cc {
                mailData["cc"] = [cc]
            }
            
            if let type = type {
                mailData["type"] = type
            }
            
            if let claimRef = claimReference {
                mailData["claimReference"] = claimRef
            }
            
            if let docId = customDocId {
                try await db.collection("mail").document(docId).setData(mailData)
            } else {
                _ = try await db.collection("mail").addDocument(data: mailData)
            }
            
            print("✅ Email queued in Firestore successfully")
            return true
        } catch {
            print("❌ Failed to queue email in Firestore: \(error.localizedDescription)")
            return false
        }
    }
}
