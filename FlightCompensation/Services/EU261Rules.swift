import Foundation

/// Compensation rules of Regulation (EC) 261/2004 and the retained UK version (UK261).
///
/// Pure Foundation, no UI or network: every legal decision the app makes lives here so it can be
/// unit tested (`swift test` in `Tests/EU261Core`). References:
/// - Art. 3(1): scope (departure from EU, or arrival in EU on a Community carrier)
/// - Art. 5(1)(c): cancellation notice / re-routing exemptions
/// - Art. 5(3): extraordinary circumstances
/// - Art. 7(1): €250 / €400 / €600 by great-circle distance; intra-Community flights > 1,500 km capped at €400
/// - Art. 7(2): 50 % reduction when re-routed arrival is within 2h / 3h / 4h
/// - CJEU Sturgeon (C-402/07, C-432/07): arrival delay ≥ 3h is compensated like a cancellation;
///   for > 3,500 km (non intra-Community) a 3–4h delay is reduced to €300
enum PassengerRightsRegime: String, Codable, Equatable {
    case eu261 = "EU261"
    case uk261 = "UK261"

    var displayName: String {
        switch self {
        case .eu261: return "EU Regulation 261/2004"
        case .uk261: return "UK Regulation 261/2004 (UK261)"
        }
    }

    var currency: String {
        switch self {
        case .eu261: return "EUR"
        case .uk261: return "GBP"
        }
    }

    /// Art. 7(1) amounts for distance bands 1, 2 and 3.
    var bandAmounts: [Int] {
        switch self {
        case .eu261: return [250, 400, 600]
        case .uk261: return [220, 350, 520]
        }
    }
}

struct EU261Input: Equatable {

    struct Rerouting: Equatable {
        /// How much earlier than the original scheduled departure the alternative flight left (0 if later).
        var departedEarlierByMinutes: Int
        /// How much later than the original scheduled arrival the passenger arrived (0 if earlier).
        var arrivedLaterByMinutes: Int
    }

    struct CancellationInfo: Equatable {
        /// Days between the passenger being told about the cancellation and the scheduled departure.
        /// `nil` = passenger has not told us yet.
        var noticeDaysBeforeDeparture: Int?
        /// `true` once the passenger answered whether a re-routing was offered.
        var reroutingAnswered: Bool = false
        /// Alternative flight offered/taken, if any.
        var rerouting: Rerouting?
    }

    enum Disruption: Equatable {
        /// Arrival delay at the final destination (doors open, CJEU C-452/13). `nil` = unknown.
        case delay(arrivalDelayMinutes: Int?)
        case cancellation(CancellationInfo)
    }

    var departureIATA: String
    var arrivalIATA: String
    /// ISO 3166-1 alpha-2, `nil` when the airport is unknown.
    var departureCountry: String?
    var arrivalCountry: String?
    var distanceKm: Double?
    /// IATA code of the *operating* carrier.
    var operatingCarrier: String
    var disruption: Disruption
    /// Reason given by the airline, if any (used to flag possible extraordinary circumstances).
    var reportedReason: String?
}

struct EU261Assessment: Equatable {

    enum Outcome: Equatable {
        case eligible
        case notEligible
        /// Probably eligible, but we need an answer from the passenger before we can be sure.
        case needsInformation
    }

    enum MissingInformation: String, Equatable, CaseIterable {
        case arrivalDelay
        case cancellationNotice
        case rerouting
        case airportData
    }

    var outcome: Outcome
    var regime: PassengerRightsRegime?
    /// Amount due (or provisionally due when `outcome == .needsInformation`).
    var amount: Int
    var currency: String
    var distanceKm: Double?
    var explanation: String
    var warnings: [String] = []
    var missing: [MissingInformation] = []
    var confidence: Double

    var isEligible: Bool { outcome == .eligible }
}

enum EU261Rules {

    static let delayThresholdMinutes = 180

    // MARK: - Scope (Art. 3)

    static func regime(departureCountry: String, arrivalCountry: String, operatingCarrier: String) -> PassengerRightsRegime? {
        let depEU = EU261Jurisdiction.isEU261Country(departureCountry)
        let arrEU = EU261Jurisdiction.isEU261Country(arrivalCountry)
        let depUK = EU261Jurisdiction.isUK261Country(departureCountry)
        let arrUK = EU261Jurisdiction.isUK261Country(arrivalCountry)
        let euCarrier = EU261Jurisdiction.isEUCarrier(operatingCarrier)
        let ukCarrier = EU261Jurisdiction.isUKCarrier(operatingCarrier)

        // Art. 3(1)(a): any flight departing an EU/EEA/CH airport, whatever the airline.
        if depEU { return .eu261 }
        // UK → EU on an EU carrier is also an EU261 flight (third country → EU, Community carrier).
        if depUK && arrEU && euCarrier { return .eu261 }
        // UK261 Art. 3(1)(a): any flight departing the UK.
        if depUK { return .uk261 }
        // Art. 3(1)(b): third country → EU only when operated by a Community carrier.
        if arrEU && euCarrier { return .eu261 }
        // UK261 Art. 3(1)(b): third country → UK when operated by a UK or EU carrier.
        if arrUK && (ukCarrier || euCarrier) { return .uk261 }
        return nil
    }

    // MARK: - Distance bands (Art. 7(1))

    /// 0: ≤ 1,500 km · 1: 1,500–3,500 km or intra-Community > 1,500 km · 2: > 3,500 km.
    static func distanceBand(distanceKm: Double, isIntraRegion: Bool) -> Int {
        if distanceKm <= 1500 { return 0 }
        if isIntraRegion || distanceKm <= 3500 { return 1 }
        return 2
    }

    /// Art. 7(2): reduction threshold for re-routed arrival, by band.
    static func reductionThresholdMinutes(band: Int) -> Int {
        [120, 180, 240][band]
    }

    static func isIntraRegion(regime: PassengerRightsRegime, departureCountry: String, arrivalCountry: String) -> Bool {
        switch regime {
        case .eu261:
            return EU261Jurisdiction.isEU261Country(departureCountry) && EU261Jurisdiction.isEU261Country(arrivalCountry)
        case .uk261:
            return EU261Jurisdiction.isUK261Country(departureCountry) && EU261Jurisdiction.isUK261Country(arrivalCountry)
        }
    }

    // MARK: - Assessment

    static func assess(_ input: EU261Input) -> EU261Assessment {
        guard let depCountry = input.departureCountry, let arrCountry = input.arrivalCountry else {
            return EU261Assessment(
                outcome: .needsInformation, regime: nil, amount: 0, currency: "EUR", distanceKm: input.distanceKm,
                explanation: "We couldn't identify one of the airports (\(input.departureIATA) → \(input.arrivalIATA)). Our team will check the route manually.",
                missing: [.airportData], confidence: 0.3
            )
        }

        guard let regime = regime(departureCountry: depCountry, arrivalCountry: arrCountry, operatingCarrier: input.operatingCarrier) else {
            return EU261Assessment(
                outcome: .notEligible, regime: nil, amount: 0, currency: "EUR", distanceKm: input.distanceKm,
                explanation: "EU261 covers flights departing the EU/EEA/Switzerland, or arriving there on an EU airline. UK261 covers flights departing the UK, or arriving there on a UK or EU airline. This flight is outside both.",
                confidence: 0.95
            )
        }

        let currency = regime.currency
        guard let distance = input.distanceKm else {
            return EU261Assessment(
                outcome: .needsInformation, regime: regime, amount: regime.bandAmounts[0], currency: currency, distanceKm: nil,
                explanation: "Your flight is covered by \(regime.displayName). We couldn't compute the flight distance, so the amount shown is the minimum.",
                missing: [.airportData], confidence: 0.5
            )
        }

        let intra = isIntraRegion(regime: regime, departureCountry: depCountry, arrivalCountry: arrCountry)
        let band = distanceBand(distanceKm: distance, isIntraRegion: intra)
        let fullAmount = regime.bandAmounts[band]
        let km = Int(distance.rounded())

        var result: EU261Assessment
        switch input.disruption {
        case .delay(let minutes):
            result = assessDelay(minutes: minutes, band: band, fullAmount: fullAmount, regime: regime, km: km)
        case .cancellation(let info):
            result = assessCancellation(info: info, band: band, fullAmount: fullAmount, regime: regime, km: km)
        }
        result.distanceKm = distance

        if result.outcome != .notEligible, let reason = input.reportedReason, let warning = extraordinaryCircumstancesWarning(for: reason) {
            result.warnings.append(warning)
            result.confidence = min(result.confidence, 0.6)
        }
        return result
    }

    private static func assessDelay(minutes: Int?, band: Int, fullAmount: Int, regime: PassengerRightsRegime, km: Int) -> EU261Assessment {
        let currency = regime.currency
        guard let minutes else {
            return EU261Assessment(
                outcome: .needsInformation, regime: regime, amount: fullAmount, currency: currency, distanceKm: nil,
                explanation: "If you reached your final destination 3 or more hours late, you're entitled to up to \(format(fullAmount, currency)) for this \(km) km flight. Tell us when you actually arrived.",
                missing: [.arrivalDelay], confidence: 0.5
            )
        }

        guard minutes >= delayThresholdMinutes else {
            return EU261Assessment(
                outcome: .notEligible, regime: regime, amount: 0, currency: currency, distanceKm: nil,
                explanation: "You arrived \(formatDuration(minutes)) late. Compensation under \(regime.rawValue) starts at an arrival delay of 3 hours.",
                confidence: 0.95
            )
        }

        // Sturgeon + Art. 7(2)(c): long-haul delay between 3h and 4h is paid at 50 %.
        if band == 2 && minutes < 240 {
            let reduced = fullAmount / 2
            return EU261Assessment(
                outcome: .eligible, regime: regime, amount: reduced, currency: currency, distanceKm: nil,
                explanation: "You arrived \(formatDuration(minutes)) late on a \(km) km flight. Long-haul delays between 3 and 4 hours are compensated at 50 %: \(format(reduced, currency)).",
                confidence: 0.9
            )
        }

        return EU261Assessment(
            outcome: .eligible, regime: regime, amount: fullAmount, currency: currency, distanceKm: nil,
            explanation: "You arrived \(formatDuration(minutes)) late on a \(km) km flight. Under \(regime.displayName) you're entitled to \(format(fullAmount, currency)).",
            confidence: 0.9
        )
    }

    private static func assessCancellation(info: EU261Input.CancellationInfo, band: Int, fullAmount: Int, regime: PassengerRightsRegime, km: Int) -> EU261Assessment {
        let currency = regime.currency
        var missing: [EU261Assessment.MissingInformation] = []

        guard let notice = info.noticeDaysBeforeDeparture else {
            missing.append(.cancellationNotice)
            if !info.reroutingAnswered { missing.append(.rerouting) }
            return EU261Assessment(
                outcome: .needsInformation, regime: regime, amount: fullAmount, currency: currency, distanceKm: nil,
                explanation: "Cancellations announced less than 14 days before departure can be worth up to \(format(fullAmount, currency)) for this \(km) km flight. Tell us when the airline informed you.",
                missing: missing, confidence: 0.5
            )
        }

        // Art. 5(1)(c)(i)
        if notice >= 14 {
            return EU261Assessment(
                outcome: .notEligible, regime: regime, amount: 0, currency: currency, distanceKm: nil,
                explanation: "The airline told you about the cancellation \(notice) days before departure. No compensation is due when notice is 14 days or more (you're still entitled to a refund or re-routing).",
                confidence: 0.95
            )
        }

        if !info.reroutingAnswered {
            return EU261Assessment(
                outcome: .needsInformation, regime: regime, amount: fullAmount, currency: currency, distanceKm: nil,
                explanation: "You were informed \(notice) days before departure. Tell us whether the airline offered you an alternative flight, so we can confirm the amount (up to \(format(fullAmount, currency))).",
                missing: [.rerouting], confidence: 0.6
            )
        }

        if let reroute = info.rerouting {
            // Art. 5(1)(c)(ii): 7–13 days notice, alternative leaves ≤ 2h earlier and arrives < 4h later.
            if notice >= 7 && reroute.departedEarlierByMinutes <= 120 && reroute.arrivedLaterByMinutes < 240 {
                return EU261Assessment(
                    outcome: .notEligible, regime: regime, amount: 0, currency: currency, distanceKm: nil,
                    explanation: "You were informed \(notice) days ahead and offered an alternative leaving at most 2 hours earlier and arriving less than 4 hours later. In that case no compensation is due.",
                    confidence: 0.9
                )
            }
            // Art. 5(1)(c)(iii): < 7 days notice, alternative leaves ≤ 1h earlier and arrives < 2h later.
            if notice < 7 && reroute.departedEarlierByMinutes <= 60 && reroute.arrivedLaterByMinutes < 120 {
                return EU261Assessment(
                    outcome: .notEligible, regime: regime, amount: 0, currency: currency, distanceKm: nil,
                    explanation: "You were offered an alternative leaving at most 1 hour earlier and arriving less than 2 hours later. In that case no compensation is due.",
                    confidence: 0.9
                )
            }
            // Art. 7(2): 50 % if the re-routed arrival is within 2h / 3h / 4h.
            if reroute.arrivedLaterByMinutes <= reductionThresholdMinutes(band: band) {
                let reduced = fullAmount / 2
                return EU261Assessment(
                    outcome: .eligible, regime: regime, amount: reduced, currency: currency, distanceKm: nil,
                    explanation: "Your flight was cancelled and the alternative got you there \(formatDuration(reroute.arrivedLaterByMinutes)) late. The airline may reduce compensation by 50 % in this case: \(format(reduced, currency)).",
                    confidence: 0.85
                )
            }
        }

        return EU261Assessment(
            outcome: .eligible, regime: regime, amount: fullAmount, currency: currency, distanceKm: nil,
            explanation: "Your \(km) km flight was cancelled \(notice) days before departure. Under \(regime.displayName) you're entitled to \(format(fullAmount, currency)).",
            confidence: 0.85
        )
    }

    // MARK: - Extraordinary circumstances (Art. 5(3))

    private static let extraordinaryKeywords = [
        "weather", "storm", "snow", "fog", "hurricane", "volcan", "ash cloud",
        "air traffic control", "atc", "air traffic", "airport closure", "airport closed",
        "security", "terror", "bird strike", "birdstrike", "political", "medical emergency",
        "drone", "meteo", "tormenta", "niebla", "huelga de controladores"
    ]
    /// Causes the CJEU has held are *not* extraordinary (technical faults: C-549/07 Wallentin-Hermann;
    /// the airline's own staff strike: C-28/20 Airhelp v SAS).
    private static let nonExtraordinaryKeywords = [
        "technical", "crew", "staff strike", "pilot strike", "operational", "rotation", "late arrival of aircraft"
    ]

    static func extraordinaryCircumstancesWarning(for reason: String) -> String? {
        let text = reason.lowercased()
        // Match at word starts so "atc" doesn't hit "match" but "volcan" still hits "volcanic".
        func mentions(_ keyword: String) -> Bool {
            text.range(of: "\\b" + NSRegularExpression.escapedPattern(for: keyword), options: .regularExpression) != nil
        }
        if nonExtraordinaryKeywords.contains(where: mentions) { return nil }
        guard extraordinaryKeywords.contains(where: mentions) else { return nil }
        return "The airline gave \"\(reason)\" as the reason. It may argue extraordinary circumstances (Art. 5(3)), which would exempt it from paying. We'll check the facts before filing."
    }

    // MARK: - Formatting

    static func format(_ amount: Int, _ currency: String) -> String {
        currency == "GBP" ? "£\(amount)" : "€\(amount)"
    }

    static func formatDuration(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}
