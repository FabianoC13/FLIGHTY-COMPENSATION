import Foundation

// MARK: - Payout Recipient

/// Represents a customer's bank/card details for receiving compensation
struct PayoutRecipient: Identifiable, Codable {
    let id: UUID
    let claimId: UUID
    let customerId: UUID
    
    // Identity
    var firstName: String
    var lastName: String
    var email: String
    var phone: String?
    
    // Location & compliance
    var country: String // ISO 2-letter code (e.g., "ES", "IT", "DE")
    var addressStreet: String
    var addressCity: String
    var addressPostal: String
    var dateOfBirth: Date?
    var documentType: PayoutDocumentType
    var documentNumber: String
    
    // Payout method
    var payoutMethod: PayoutMethod
    
    // Bank details (if .bank)
    var iban: String?
    var bic: String? // SWIFT/BIC code
    var accountHolderName: String?
    var bankName: String? // Optional, can be inferred from BIC
    
    // Card details (if .card - tokenized by dLocal)
    var cardToken: String?
    var cardLast4: String?
    var cardBrand: String?
    
    // Preferences
    var currencyPreferred: String // "EUR", "USD", "GBP", etc.
    
    // Status
    var status: RecipientStatus
    var validationErrors: [String]?
    var kycScreeningResult: KYCResult?
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    
    init(claimId: UUID, customerId: UUID) {
        self.id = UUID()
        self.claimId = claimId
        self.customerId = customerId
        self.firstName = ""
        self.lastName = ""
        self.email = ""
        self.country = "ES" // Default to Spain
        self.addressStreet = ""
        self.addressCity = ""
        self.addressPostal = ""
        self.documentType = .passport
        self.documentNumber = ""
        self.payoutMethod = .bank
        self.currencyPreferred = "EUR"
        self.status = .pending
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var isValid: Bool {
        guard !firstName.isEmpty,
              !lastName.isEmpty,
              !email.isEmpty,
              !country.isEmpty,
              !addressStreet.isEmpty,
              !addressCity.isEmpty,
              !addressPostal.isEmpty,
              !documentNumber.isEmpty else {
            return false
        }
        
        switch payoutMethod {
        case .bank:
            guard let iban = iban, !iban.isEmpty,
                  let accountHolderName = accountHolderName, !accountHolderName.isEmpty else {
                return false
            }
            return IBANValidator.validate(iban)
        case .card:
            return cardToken != nil
        }
    }
    
    var maskedIBAN: String? {
        guard let iban = iban, iban.count > 8 else { return iban }
        let prefix = String(iban.prefix(4))
        let suffix = String(iban.suffix(4))
        return "\(prefix) •••• •••• \(suffix)"
    }
}

enum PayoutMethod: String, Codable, CaseIterable, Identifiable {
    case bank = "Bank Transfer"
    case card = "Card"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .bank: return "building.columns"
        case .card: return "creditcard"
        }
    }
}

enum PayoutDocumentType: String, Codable, CaseIterable, Identifiable {
    case dni = "DNI"
    case passport = "Passport"
    case nie = "NIE"
    case driverLicense = "Driver's License"
    
    var id: String { rawValue }
}

enum RecipientStatus: String, Codable {
    case pending = "Pending"
    case verified = "Verified"
    case invalid = "Invalid"
    case blocked = "Blocked"
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .verified: return "green"
        case .invalid: return "red"
        case .blocked: return "red"
        }
    }
}

enum KYCResult: String, Codable {
    case passed = "Passed"
    case flagged = "Flagged"
    case blocked = "Blocked"
}

// MARK: - Payout

/// Represents an outbound payment to a customer
struct Payout: Identifiable, Codable {
    let id: UUID
    let claimId: UUID
    let recipientId: UUID
    
    // Amounts
    var amountEUR: Decimal
    var currencyDestination: String
    var fxRate: Decimal?
    var amountDestination: Decimal?
    
    // Provider info
    var provider: PayoutProvider
    var providerPayoutId: String?
    
    // Status tracking
    var status: PayoutStatus
    var failureReason: String?
    var failureCode: String?
    
    // Timestamps
    var createdAt: Date
    var queuedAt: Date?
    var sentAt: Date?
    var settledAt: Date?
    
    // Retries
    var retryCount: Int
    var nextRetryAt: Date?
    
    // Webhook tracking
    var webhookLastEvent: String?
    var webhookLastEventAt: Date?
    
    init(claimId: UUID, recipientId: UUID, amountEUR: Decimal, currencyDestination: String = "EUR") {
        self.id = UUID()
        self.claimId = claimId
        self.recipientId = recipientId
        self.amountEUR = amountEUR
        self.currencyDestination = currencyDestination
        self.provider = .dlocal
        self.status = .pending
        self.createdAt = Date()
        self.retryCount = 0
    }
}

enum PayoutProvider: String, Codable {
    case dlocal = "dLocal"
    case interbank = "Interbank"
    case manual = "Manual"
}

enum PayoutStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case queued = "Queued"
    case processing = "Processing"
    case sent = "Sent"
    case settled = "Settled"
    case failed = "Failed"
    case cancelled = "Cancelled"
    
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .queued: return "list.bullet"
        case .processing: return "arrow.triangle.2.circlepath"
        case .sent: return "paperplane.fill"
        case .settled: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .cancelled: return "minus.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .pending, .queued: return "orange"
        case .processing, .sent: return "blue"
        case .settled: return "green"
        case .failed, .cancelled: return "red"
        }
    }
    
    var displayText: String {
        switch self {
        case .pending: return "Awaiting AESA Settlement"
        case .queued: return "Payment Queued"
        case .processing: return "Processing Payment"
        case .sent: return "Payment Sent"
        case .settled: return "Payment Received"
        case .failed: return "Payment Failed"
        case .cancelled: return "Payment Cancelled"
        }
    }
}

// MARK: - Bank Reconciliation

/// Tracks incoming funds from AESA to match against claims
struct BankReconciliation: Identifiable, Codable {
    let id: UUID
    var bankRef: String // MT940 reference or wire ID
    var amountEUR: Decimal
    var receivedAt: Date
    var matchedClaimId: UUID?
    var matchedAt: Date?
    var status: ReconciliationStatus
    var notes: String?
    var createdAt: Date
    
    init(bankRef: String, amountEUR: Decimal, receivedAt: Date) {
        self.id = UUID()
        self.bankRef = bankRef
        self.amountEUR = amountEUR
        self.receivedAt = receivedAt
        self.status = .pendingMatch
        self.createdAt = Date()
    }
}

enum ReconciliationStatus: String, Codable {
    case pendingMatch = "Pending Match"
    case matched = "Matched"
    case unmatchedHold = "Unmatched Hold"
    case orphan = "Orphan"
}

// MARK: - Supported Countries

struct PayoutCountry: Identifiable, Codable {
    let code: String // ISO 2-letter
    let name: String
    let currency: String
    let requiresBIC: Bool
    let requiresDOB: Bool
    let ibanPrefix: String?
    let ibanLength: Int?
    
    var id: String { code }
    
    static let supported: [PayoutCountry] = [
        PayoutCountry(code: "ES", name: "Spain", currency: "EUR", requiresBIC: false, requiresDOB: true, ibanPrefix: "ES", ibanLength: 24),
        PayoutCountry(code: "IT", name: "Italy", currency: "EUR", requiresBIC: false, requiresDOB: true, ibanPrefix: "IT", ibanLength: 27),
        PayoutCountry(code: "DE", name: "Germany", currency: "EUR", requiresBIC: false, requiresDOB: false, ibanPrefix: "DE", ibanLength: 22),
        PayoutCountry(code: "FR", name: "France", currency: "EUR", requiresBIC: false, requiresDOB: false, ibanPrefix: "FR", ibanLength: 27),
        PayoutCountry(code: "PT", name: "Portugal", currency: "EUR", requiresBIC: false, requiresDOB: false, ibanPrefix: "PT", ibanLength: 25),
        PayoutCountry(code: "NL", name: "Netherlands", currency: "EUR", requiresBIC: false, requiresDOB: false, ibanPrefix: "NL", ibanLength: 18),
        PayoutCountry(code: "BE", name: "Belgium", currency: "EUR", requiresBIC: false, requiresDOB: false, ibanPrefix: "BE", ibanLength: 16),
        PayoutCountry(code: "AT", name: "Austria", currency: "EUR", requiresBIC: false, requiresDOB: false, ibanPrefix: "AT", ibanLength: 20),
        PayoutCountry(code: "IE", name: "Ireland", currency: "EUR", requiresBIC: false, requiresDOB: false, ibanPrefix: "IE", ibanLength: 22),
        PayoutCountry(code: "GR", name: "Greece", currency: "EUR", requiresBIC: false, requiresDOB: false, ibanPrefix: "GR", ibanLength: 27),
        PayoutCountry(code: "PL", name: "Poland", currency: "PLN", requiresBIC: false, requiresDOB: false, ibanPrefix: "PL", ibanLength: 28),
        PayoutCountry(code: "SE", name: "Sweden", currency: "SEK", requiresBIC: false, requiresDOB: false, ibanPrefix: "SE", ibanLength: 24),
        PayoutCountry(code: "DK", name: "Denmark", currency: "DKK", requiresBIC: false, requiresDOB: false, ibanPrefix: "DK", ibanLength: 18),
        PayoutCountry(code: "NO", name: "Norway", currency: "NOK", requiresBIC: false, requiresDOB: false, ibanPrefix: "NO", ibanLength: 15),
        PayoutCountry(code: "CH", name: "Switzerland", currency: "CHF", requiresBIC: true, requiresDOB: false, ibanPrefix: "CH", ibanLength: 21),
        PayoutCountry(code: "GB", name: "United Kingdom", currency: "GBP", requiresBIC: true, requiresDOB: false, ibanPrefix: "GB", ibanLength: 22),
        PayoutCountry(code: "US", name: "United States", currency: "USD", requiresBIC: true, requiresDOB: false, ibanPrefix: nil, ibanLength: nil),
    ]
    
    static func find(byCode code: String) -> PayoutCountry? {
        supported.first { $0.code == code }
    }
}

// MARK: - Claim Status Extension (for payout tracking)

enum ClaimPayoutStatus: String, Codable {
    case noBankDetails = "Add Payment Details"
    case awaitingFunds = "Awaiting AESA Settlement"
    case payoutQueued = "Payment Queued"
    case payoutProcessing = "Processing Payment"
    case payoutSent = "Payment Sent"
    case payoutSettled = "Payment Received"
    case payoutFailed = "Payment Failed - Action Needed"
}
