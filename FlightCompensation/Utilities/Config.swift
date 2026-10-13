import Foundation

/// App configuration.
///
/// Values are read from Info.plist (filled at build time from `Config/App.xcconfig` and the
/// git-ignored `Config/Secrets.xcconfig`), then from the process environment (Xcode scheme),
/// so nothing secret or company-specific is hard-coded. See `docs/PRODUCTION_CHECKLIST.md`.
enum Config {
    private static let placeholderAPIKey = "YOUR_KEY|YOUR_SECRET"

    /// Info.plist first, then environment. Unexpanded `$(VAR)` build settings count as missing.
    static func value(_ key: String) -> String? {
        if let plist = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            let trimmed = plist.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !trimmed.hasPrefix("$(") { return trimmed }
        }
        if let env = ProcessInfo.processInfo.environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !env.isEmpty {
            return env
        }
        return nil
    }

    // MARK: - Flight data

    /// FlightRadar24 API key, format `{key-id}|{key-secret}`.
    static var flightRadar24APIKey: String {
        value("FLIGHT_RADAR24_API_KEY") ?? placeholderAPIKey
    }

    static var flightRadar24UsesSandbox: Bool {
        isTruthy(value("FLIGHT_RADAR24_SANDBOX"))
    }

    /// Use the real API when a key is configured, unless overridden.
    static var useRealFlightTracking: Bool {
        if let override = value("USE_REAL_FLIGHT_TRACKING") {
            return isTruthy(override)
        }
        return flightRadar24APIKey != placeholderAPIKey
    }

    // MARK: - Company (appears in the documents passengers sign)

    static var companyLegalName: String { value("COMPANY_LEGAL_NAME") ?? "[COMPANY LEGAL NAME]" }
    static var companyRegistrationNumber: String { value("COMPANY_REGISTRATION_NUMBER") ?? "[TAX ID]" }
    static var companyAddress: String { value("COMPANY_ADDRESS") ?? "[REGISTERED ADDRESS]" }
    static var companyEmail: String { value("COMPANY_EMAIL") ?? "claims@example.com" }
    /// Inbox that receives every claim; also the CC on manual emails to airlines.
    static var claimsOpsEmail: String { value("CLAIMS_OPS_EMAIL") ?? companyEmail }
    /// Client-money account airlines pay into. Shown in the airline letter only when set.
    static var collectionIBAN: String? { value("COLLECTION_IBAN") }
    static var collectionBIC: String? { value("COLLECTION_BIC") }
    static var termsURL: String { value("TERMS_URL") ?? "https://example.com/terms" }
    static var privacyURL: String { value("PRIVACY_URL") ?? "https://example.com/privacy" }
    /// Law governing the service contract (consumer's mandatory home-country law always applies too).
    static var governingLaw: String { value("GOVERNING_LAW") ?? "Spain" }

    /// Success fee as a percentage of the compensation recovered, VAT included.
    static var successFeePercent: Int { Int(value("SUCCESS_FEE_PERCENT") ?? "") ?? 25 }
    /// Extra percentage only when the claim has to go to court.
    static var legalActionFeePercent: Int { Int(value("LEGAL_ACTION_FEE_PERCENT") ?? "") ?? 10 }

    /// True once the legal entity used in signed documents has been configured.
    /// Release builds refuse to submit claims until it is, so nobody signs a document naming a placeholder.
    static var isLegalEntityConfigured: Bool {
        value("COMPANY_LEGAL_NAME") != nil && value("COMPANY_REGISTRATION_NUMBER") != nil && value("COMPANY_ADDRESS") != nil
    }

    static var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(version) (\(build))"
    }

    static func netPayout(for amount: Int) -> Int {
        amount - Int((Double(amount) * Double(successFeePercent) / 100).rounded())
    }

    private static func isTruthy(_ value: String?) -> Bool {
        guard let value = value?.lowercased() else { return false }
        return value == "1" || value == "true" || value == "yes"
    }
}
