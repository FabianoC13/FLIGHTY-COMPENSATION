import Foundation

/// Service for managing customer payout recipients and payouts
/// Communicates with the backend server for payout operations
final class PayoutService {
    static let shared = PayoutService()
    
    private init() {}
    
    // MARK: - Recipient Management
    
    /// Save or update recipient payout details
    func saveRecipient(_ recipient: PayoutRecipient) async throws -> PayoutRecipient {
        // Use local persistence for now to avoid localhost dependency
        return try await saveRecipientLocally(recipient)
    }
    
    /// Get recipient for a claim
    func getRecipient(forClaimId claimId: UUID) async throws -> PayoutRecipient? {
        return try await getRecipientLocally(forClaimId: claimId)
    }
    
    /// Validate recipient details before saving
    func validateRecipient(_ recipient: PayoutRecipient) -> [String] {
        var errors: [String] = []
        
        // Basic fields
        if recipient.firstName.isEmpty {
            errors.append("First name is required")
        }
        if recipient.lastName.isEmpty {
            errors.append("Last name is required")
        }
        if recipient.email.isEmpty {
            errors.append("Email is required")
        } else if !isValidEmail(recipient.email) {
            errors.append("Invalid email format")
        }
        
        // Address
        if recipient.addressStreet.isEmpty {
            errors.append("Street address is required")
        }
        if recipient.addressCity.isEmpty {
            errors.append("City is required")
        }
        if recipient.addressPostal.isEmpty {
            errors.append("Postal code is required")
        }
        if recipient.country.isEmpty {
            errors.append("Country is required")
        }
        
        // Document
        if recipient.documentNumber.isEmpty {
            errors.append("Document number is required")
        }
        
        // Country-specific requirements
        if let country = PayoutCountry.find(byCode: recipient.country) {
            if country.requiresDOB && recipient.dateOfBirth == nil {
                errors.append("Date of birth is required for \(country.name)")
            }
        }
        
        // Payout method specific
        switch recipient.payoutMethod {
        case .bank:
            if let iban = recipient.iban, !iban.isEmpty {
                let result = IBANValidator.validateWithDetails(iban)
                if !result.isValid, let error = result.errorMessage {
                    errors.append(error)
                }
                
                // Check country matches
                if let ibanCountry = result.countryCode, ibanCountry != recipient.country {
                    errors.append("IBAN country (\(ibanCountry)) doesn't match selected country (\(recipient.country))")
                }
            } else {
                errors.append("IBAN is required for bank transfers")
            }
            
            if recipient.accountHolderName?.isEmpty ?? true {
                errors.append("Account holder name is required")
            }
            
            // Check if BIC is required
            if let country = PayoutCountry.find(byCode: recipient.country), country.requiresBIC {
                if recipient.bic?.isEmpty ?? true {
                    errors.append("BIC/SWIFT code is required for \(country.name)")
                }
            }
            
        case .card:
            if recipient.cardToken == nil {
                errors.append("Card details are required")
            }
        }
        
        return errors
    }
    
    // MARK: - Payout Operations
    
    /// Get payout status for a claim
    func getPayout(forClaimId claimId: UUID) async throws -> Payout? {
        return try await getPayoutLocally(forClaimId: claimId)
    }
    
    /// Request manual retry of a failed payout
    func retryPayout(payoutId: UUID) async throws -> Payout {
        // Since we are using local storage, retry simply returns the existing payout if found
        // In a real app, this would trigger a new background process
        throw PayoutError.notAvailable
    }
    
    // MARK: - Local Storage (for device builds)
    
    private let recipientsKey = "saved_recipients"
    private let payoutsKey = "saved_payouts"
    
    private func saveRecipientLocally(_ recipient: PayoutRecipient) async throws -> PayoutRecipient {
        var recipients = loadRecipientsFromDisk()
        
        // Remove existing recipient for this claim if any
        recipients.removeAll { $0.claimId == recipient.claimId }
        
        // Add updated recipient
        var updatedRecipient = recipient
        updatedRecipient.updatedAt = Date()
        recipients.append(updatedRecipient)
        
        saveRecipientsToDisk(recipients)
        return updatedRecipient
    }
    
    private func getRecipientLocally(forClaimId claimId: UUID) async throws -> PayoutRecipient? {
        let recipients = loadRecipientsFromDisk()
        return recipients.first { $0.claimId == claimId }
    }
    
    private func getPayoutLocally(forClaimId claimId: UUID) async throws -> Payout? {
        let payouts = loadPayoutsFromDisk()
        return payouts.first { $0.claimId == claimId }
    }
    
    private func loadRecipientsFromDisk() -> [PayoutRecipient] {
        guard let data = UserDefaults.standard.data(forKey: recipientsKey) else {
            return []
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([PayoutRecipient].self, from: data)) ?? []
    }
    
    private func saveRecipientsToDisk(_ recipients: [PayoutRecipient]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(recipients) {
            UserDefaults.standard.set(data, forKey: recipientsKey)
        }
    }
    
    private func loadPayoutsFromDisk() -> [Payout] {
        guard let data = UserDefaults.standard.data(forKey: payoutsKey) else {
            return []
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Payout].self, from: data)) ?? []
    }
    
    // MARK: - Helpers
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
}

// MARK: - Error Types

enum PayoutError: LocalizedError {
    case invalidResponse
    case serverError(String)
    case validationFailed([String])
    case notAvailable
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return "Server error: \(message)"
        case .validationFailed(let errors):
            return errors.joined(separator: "\n")
        case .notAvailable:
            return "This operation is not available"
        }
    }
}

private struct ErrorResponse: Codable {
    let error: String
}
