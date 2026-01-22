import Foundation

/// IBAN Validation Utility
/// Validates IBAN format, checksum, and country-specific rules
struct IBANValidator {
    
    // MARK: - Public API
    
    /// Validate an IBAN string
    /// - Parameter iban: The IBAN to validate (with or without spaces)
    /// - Returns: true if valid, false otherwise
    static func validate(_ iban: String) -> Bool {
        let cleanIBAN = sanitize(iban)
        
        guard cleanIBAN.count >= 15, cleanIBAN.count <= 34 else {
            return false
        }
        
        guard isValidFormat(cleanIBAN) else {
            return false
        }
        
        guard isValidChecksum(cleanIBAN) else {
            return false
        }
        
        // Country-specific length validation
        if let expectedLength = countryIBANLengths[String(cleanIBAN.prefix(2))] {
            guard cleanIBAN.count == expectedLength else {
                return false
            }
        }
        
        return true
    }
    
    /// Validate IBAN and return detailed result
    static func validateWithDetails(_ iban: String) -> IBANValidationResult {
        let cleanIBAN = sanitize(iban)
        
        guard cleanIBAN.count >= 15 else {
            return IBANValidationResult(isValid: false, error: .tooShort, sanitizedIBAN: cleanIBAN)
        }
        
        guard cleanIBAN.count <= 34 else {
            return IBANValidationResult(isValid: false, error: .tooLong, sanitizedIBAN: cleanIBAN)
        }
        
        guard isValidFormat(cleanIBAN) else {
            return IBANValidationResult(isValid: false, error: .invalidFormat, sanitizedIBAN: cleanIBAN)
        }
        
        let countryCode = String(cleanIBAN.prefix(2))
        
        if let expectedLength = countryIBANLengths[countryCode] {
            guard cleanIBAN.count == expectedLength else {
                return IBANValidationResult(
                    isValid: false,
                    error: .invalidLengthForCountry(expected: expectedLength, actual: cleanIBAN.count),
                    sanitizedIBAN: cleanIBAN,
                    countryCode: countryCode
                )
            }
        }
        
        guard isValidChecksum(cleanIBAN) else {
            return IBANValidationResult(isValid: false, error: .invalidChecksum, sanitizedIBAN: cleanIBAN, countryCode: countryCode)
        }
        
        return IBANValidationResult(
            isValid: true,
            error: nil,
            sanitizedIBAN: cleanIBAN,
            countryCode: countryCode,
            formattedIBAN: format(cleanIBAN)
        )
    }
    
    /// Format IBAN with spaces every 4 characters
    static func format(_ iban: String) -> String {
        let clean = sanitize(iban)
        var formatted = ""
        for (index, char) in clean.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted.append(char)
        }
        return formatted
    }
    
    /// Remove spaces and convert to uppercase
    static func sanitize(_ iban: String) -> String {
        iban.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .uppercased()
    }
    
    /// Extract BIC from IBAN (if known mapping exists)
    static func inferBIC(fromIBAN iban: String) -> String? {
        let clean = sanitize(iban)
        guard clean.count >= 8 else { return nil }
        
        let countryCode = String(clean.prefix(2))
        let bankCode = String(clean.dropFirst(4).prefix(4))
        
        // Common Spanish banks
        if countryCode == "ES" {
            return spanishBankBICs[bankCode]
        }
        
        // Add more country-specific mappings as needed
        return nil
    }
    
    // MARK: - Private Helpers
    
    private static func isValidFormat(_ iban: String) -> Bool {
        // First two characters must be letters (country code)
        let countryCode = String(iban.prefix(2))
        guard countryCode.allSatisfy({ $0.isLetter }) else {
            return false
        }
        
        // Characters 3-4 must be digits (check digits)
        let checkDigits = String(iban.dropFirst(2).prefix(2))
        guard checkDigits.allSatisfy({ $0.isNumber }) else {
            return false
        }
        
        // Rest must be alphanumeric
        let bban = String(iban.dropFirst(4))
        guard bban.allSatisfy({ $0.isLetter || $0.isNumber }) else {
            return false
        }
        
        return true
    }
    
    private static func isValidChecksum(_ iban: String) -> Bool {
        // Move first 4 characters to the end
        let rearranged = String(iban.dropFirst(4)) + String(iban.prefix(4))
        
        // Convert letters to numbers (A=10, B=11, ..., Z=35)
        var numericString = ""
        for char in rearranged {
            if char.isLetter {
                let value = Int(char.asciiValue!) - Int(Character("A").asciiValue!) + 10
                numericString += String(value)
            } else {
                numericString += String(char)
            }
        }
        
        // Perform mod 97 on the numeric string
        // For large numbers, we process in chunks
        var remainder = 0
        for chunk in numericString.chunked(size: 9) {
            if let value = Int(String(remainder) + chunk) {
                remainder = value % 97
            }
        }
        
        return remainder == 1
    }
    
    // MARK: - Country IBAN Lengths
    
    private static let countryIBANLengths: [String: Int] = [
        "AL": 28, "AD": 24, "AT": 20, "AZ": 28, "BH": 22, "BY": 28, "BE": 16, "BA": 20,
        "BR": 29, "BG": 22, "CR": 22, "HR": 21, "CY": 28, "CZ": 24, "DK": 18, "DO": 28,
        "TL": 23, "EE": 20, "FO": 18, "FI": 18, "FR": 27, "GE": 22, "DE": 22, "GI": 23,
        "GR": 27, "GL": 18, "GT": 28, "HU": 28, "IS": 26, "IQ": 23, "IE": 22, "IL": 23,
        "IT": 27, "JO": 30, "KZ": 20, "XK": 20, "KW": 30, "LV": 21, "LB": 28, "LI": 21,
        "LT": 20, "LU": 20, "MK": 19, "MT": 31, "MR": 27, "MU": 30, "MC": 27, "MD": 24,
        "ME": 22, "NL": 18, "NO": 15, "PK": 24, "PS": 29, "PL": 28, "PT": 25, "QA": 29,
        "RO": 24, "SM": 27, "SA": 24, "RS": 22, "SC": 31, "SK": 24, "SI": 19, "ES": 24,
        "SE": 24, "CH": 21, "TN": 24, "TR": 26, "UA": 29, "AE": 23, "GB": 22, "VA": 22,
        "VG": 24
    ]
    
    // MARK: - Spanish Bank BIC Codes
    
    private static let spanishBankBICs: [String: String] = [
        "0049": "BSCHESMMXXX", // Santander
        "2100": "CAIXESBBXXX", // CaixaBank
        "0182": "BBVAESMMXXX", // BBVA
        "0081": "BSABESBBXXX", // Sabadell
        "2085": "CAZABOROXXX", // Ibercaja
        "0128": "BKBKESMMXXX", // Bankinter
        "0030": "ESPCESMMXXX", // Banco Español de Crédito
        "0075": "POPUESMMXXX", // Banco Popular
        "0487": "GBMNESMMXXX", // Banco Mare Nostrum
        "2038": "CAABOROXXX", // Caja de Ahorros de Asturias
        "0073": "OPENESMMXXX", // Open Bank
    ]
}

// MARK: - Validation Result

struct IBANValidationResult {
    let isValid: Bool
    let error: IBANValidationError?
    let sanitizedIBAN: String
    var countryCode: String?
    var formattedIBAN: String?
    
    var errorMessage: String? {
        error?.message
    }
}

enum IBANValidationError {
    case tooShort
    case tooLong
    case invalidFormat
    case invalidChecksum
    case invalidLengthForCountry(expected: Int, actual: Int)
    case unsupportedCountry
    
    var message: String {
        switch self {
        case .tooShort:
            return "IBAN is too short"
        case .tooLong:
            return "IBAN is too long"
        case .invalidFormat:
            return "IBAN has invalid format"
        case .invalidChecksum:
            return "IBAN checksum is invalid"
        case .invalidLengthForCountry(let expected, let actual):
            return "IBAN should be \(expected) characters for this country (got \(actual))"
        case .unsupportedCountry:
            return "Country not supported for IBAN validation"
        }
    }
}

// MARK: - String Extension for Chunking

private extension String {
    func chunked(size: Int) -> [Substring] {
        var chunks: [Substring] = []
        var startIndex = self.startIndex
        while startIndex < self.endIndex {
            let endIndex = self.index(startIndex, offsetBy: size, limitedBy: self.endIndex) ?? self.endIndex
            chunks.append(self[startIndex..<endIndex])
            startIndex = endIndex
        }
        return chunks
    }
}
