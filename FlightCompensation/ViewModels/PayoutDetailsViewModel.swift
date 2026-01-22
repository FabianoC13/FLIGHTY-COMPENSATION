import Foundation
import SwiftUI

/// ViewModel for the PayoutDetailsView
@MainActor
final class PayoutDetailsViewModel: ObservableObject {
    @Published var recipient: PayoutRecipient
    @Published var ibanInput: String = ""
    @Published var ibanValidationResult: IBANValidationResult?
    @Published var isValidatingIBAN: Bool = false
    @Published var inferredBIC: String?
    @Published var validationErrors: [String] = []
    @Published var isSaving: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    
    // Card-related properties
    @Published var cardNumber: String = ""
    @Published var cardExpiry: String = ""
    @Published var cardCVC: String = ""
    @Published var cardBrand: String?
    
    private let payoutService = PayoutService.shared
    
    init(claimId: UUID, customerId: UUID) {
        self.recipient = PayoutRecipient(claimId: claimId, customerId: customerId)
        
        // Pre-fill from user profile if available
        if let profile = UserProfileService.shared.userProfile {
            recipient.firstName = profile.firstName
            recipient.lastName = profile.lastName
            recipient.email = profile.email
            recipient.phone = profile.phoneNumber
            recipient.addressStreet = profile.address.street
            recipient.addressCity = profile.address.city
            recipient.addressPostal = profile.address.postalCode
            recipient.accountHolderName = "\(profile.firstName) \(profile.lastName)"
            
            // Map document type
            switch profile.documentType {
            case .dni:
                recipient.documentType = .dni
            case .passport:
                recipient.documentType = .passport
            case .nie:
                recipient.documentType = .nie
            }
            recipient.documentNumber = profile.documentNumber
            
            // Map country from address
            if let country = PayoutCountry.supported.first(where: { $0.name == profile.address.country }) {
                recipient.country = country.code
                recipient.currencyPreferred = country.currency
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var isFormValid: Bool {
        let errors = payoutService.validateRecipient(recipient)
        
        if recipient.payoutMethod == .bank {
            return errors.isEmpty && ibanValidationResult?.isValid == true
        } else {
            // Card validation
            let cardDigits = cardNumber.filter { $0.isNumber }
            let expiryDigits = cardExpiry.filter { $0.isNumber }
            return errors.isEmpty && 
                   cardDigits.count >= 15 && 
                   expiryDigits.count == 4 && 
                   cardCVC.count >= 3
        }
    }
    
    var requiresBIC: Bool {
        guard let country = PayoutCountry.find(byCode: recipient.country) else {
            return false
        }
        return country.requiresBIC && inferredBIC == nil
    }
    
    var requiresDOB: Bool {
        guard let country = PayoutCountry.find(byCode: recipient.country) else {
            return false
        }
        return country.requiresDOB
    }
    
    var availableCurrencies: [String] {
        var currencies = ["EUR"]
        
        if let country = PayoutCountry.find(byCode: recipient.country) {
            if country.currency != "EUR" && !currencies.contains(country.currency) {
                currencies.append(country.currency)
            }
        }
        
        // Add common currencies
        for currency in ["USD", "GBP"] {
            if !currencies.contains(currency) {
                currencies.append(currency)
            }
        }
        
        return currencies
    }
    
    // MARK: - Actions
    
    func selectCountry(_ country: PayoutCountry) {
        recipient.country = country.code
        recipient.currencyPreferred = country.currency
        
        // Re-validate IBAN if country changed
        if !ibanInput.isEmpty {
            validateIBAN(ibanInput)
        }
    }
    
    func validateIBAN(_ input: String) {
        let sanitized = IBANValidator.sanitize(input)
        
        // Format the input
        ibanInput = IBANValidator.format(sanitized)
        
        // Validate
        guard sanitized.count >= 4 else {
            ibanValidationResult = nil
            inferredBIC = nil
            recipient.iban = nil
            return
        }
        
        isValidatingIBAN = true
        
        // Debounce validation
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            let result = IBANValidator.validateWithDetails(sanitized)
            ibanValidationResult = result
            
            if result.isValid {
                recipient.iban = sanitized
                
                // Try to infer BIC
                if let bic = IBANValidator.inferBIC(fromIBAN: sanitized) {
                    inferredBIC = bic
                    recipient.bic = bic
                } else {
                    inferredBIC = nil
                }
            } else {
                recipient.iban = nil
                inferredBIC = nil
            }
            
            isValidatingIBAN = false
        }
    }
    
    // MARK: - Card Formatting
    
    func formatCardNumber(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        let limited = String(digits.prefix(16))
        
        // Detect card brand
        detectCardBrand(digits)
        
        // Format with spaces every 4 digits
        var formatted = ""
        for (index, char) in limited.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted.append(char)
        }
        
        // Store card info in recipient
        if digits.count >= 12 {
            recipient.cardLast4 = String(digits.suffix(4))
            recipient.cardBrand = cardBrand
        }
        
        return formatted
    }
    
    func formatExpiry(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        let limited = String(digits.prefix(4))
        
        if limited.count >= 2 {
            let month = String(limited.prefix(2))
            let year = String(limited.dropFirst(2))
            if year.isEmpty {
                return month
            }
            return "\(month)/\(year)"
        }
        return limited
    }
    
    private func detectCardBrand(_ digits: String) {
        guard !digits.isEmpty else {
            cardBrand = nil
            return
        }
        
        let prefix = String(digits.prefix(2))
        let firstDigit = digits.first!
        
        switch firstDigit {
        case "4":
            cardBrand = "Visa"
        case "5":
            if let prefixNum = Int(prefix), (51...55).contains(prefixNum) {
                cardBrand = "Mastercard"
            }
        case "3":
            if prefix == "34" || prefix == "37" {
                cardBrand = "Amex"
            }
        default:
            cardBrand = nil
        }
    }
    
    func saveRecipient() async -> PayoutRecipient? {
        // Validate
        validationErrors = payoutService.validateRecipient(recipient)
        
        guard validationErrors.isEmpty else {
            return nil
        }
        
        isSaving = true
        
        do {
            let savedRecipient = try await payoutService.saveRecipient(recipient)
            isSaving = false
            return savedRecipient
        } catch {
            isSaving = false
            errorMessage = error.localizedDescription
            showError = true
            return nil
        }
    }
}
