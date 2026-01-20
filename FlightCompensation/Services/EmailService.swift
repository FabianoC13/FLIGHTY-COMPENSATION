import Foundation

/// Service to send email requests to the local email server
/// This only works in the simulator where localhost is shared with the Mac
struct EmailService {
    static let shared = EmailService()
    
    #if targetEnvironment(simulator)
    private let serverURL = URL(string: "http://localhost:8080/send-email")!
    #else
    private let serverURL: URL? = nil
    #endif
    
    struct EmailAttachment {
        let filename: String
        let data: Data
    }
    
    struct EmailRequest: Encodable {
        let to: String
        let cc: String?
        let subject: String
        let body: String
        let attachments: [AttachmentPayload]
        
        struct AttachmentPayload: Encodable {
            let filename: String
            let data: String // Base64 encoded
        }
    }
    
    /// Send an email via the local server (Simulator only)
    func sendEmail(
        to: String,
        cc: String?,
        subject: String,
        body: String,
        attachments: [EmailAttachment]
    ) async -> Bool {
        #if targetEnvironment(simulator)
        do {
            var request = URLRequest(url: serverURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30
            
            let emailRequest = EmailRequest(
                to: to,
                cc: cc,
                subject: subject,
                body: body,
                attachments: attachments.map { attachment in
                    EmailRequest.AttachmentPayload(
                        filename: attachment.filename,
                        data: attachment.data.base64EncodedString()
                    )
                }
            )
            
            request.httpBody = try JSONEncoder().encode(emailRequest)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("✅ Email sent successfully via local server")
                    return true
                } else {
                    if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data) {
                        print("❌ Email server error: \(errorResponse["error"] ?? "Unknown")")
                    }
                    return false
                }
            }
            return false
        } catch {
            print("❌ Failed to send email via local server: \(error.localizedDescription)")
            return false
        }
        #else
        print("⚠️ EmailService only works in simulator")
        return false
        #endif
    }
}
