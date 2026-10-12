import Foundation

struct CompensationEligibility: Codable, Equatable, Identifiable {
    let id: UUID
    let isEligible: Bool
    let amount: Decimal
    let currency: String
    let reason: String // Plain language explanation
    let confidence: Double // 0.0 to 1.0
    /// "EU261" / "UK261" when the flight is in scope.
    var regulation: String? = nil
    var distanceKm: Double? = nil
    /// True when the amount is provisional until the passenger answers a few questions.
    var needsMoreInformation: Bool? = nil
    /// E.g. possible extraordinary circumstances.
    var warnings: [String]? = nil
    
    init(id: UUID = UUID(), isEligible: Bool, amount: Decimal, currency: String = "EUR", reason: String, confidence: Double = 1.0,
         regulation: String? = nil, distanceKm: Double? = nil, needsMoreInformation: Bool? = nil, warnings: [String]? = nil) {
        self.id = id
        self.isEligible = isEligible
        self.amount = amount
        self.currency = currency
        self.reason = reason
        self.confidence = confidence
        self.regulation = regulation
        self.distanceKm = distanceKm
        self.needsMoreInformation = needsMoreInformation
        self.warnings = warnings
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currency) \(amount)"
    }
}


