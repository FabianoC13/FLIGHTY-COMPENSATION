import Foundation

struct CompensationEligibility: Codable, Equatable, Identifiable {
    let id: UUID
    let isEligible: Bool
    let amount: Decimal
    let currency: String
    let reason: String // Plain language explanation
    let confidence: Double // 0.0 to 1.0
    
    init(id: UUID = UUID(), isEligible: Bool, amount: Decimal, currency: String = "EUR", reason: String, confidence: Double = 1.0) {
        self.id = id
        self.isEligible = isEligible
        self.amount = amount
        self.currency = currency
        self.reason = reason
        self.confidence = confidence
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currency) \(amount)"
    }
}


