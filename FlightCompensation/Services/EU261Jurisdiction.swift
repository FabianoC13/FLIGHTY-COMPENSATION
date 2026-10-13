import Foundation

/// Territorial and carrier scope for Regulation (EC) 261/2004 and its UK copy ("UK261").
///
/// Pure Foundation so it can be unit tested outside the app target (see `Tests/EU261Core`).
enum EU261Jurisdiction {

    /// ISO 3166-1 alpha-2 codes where EU261 applies to departing flights.
    /// EU-27 + EEA (IS, NO, LI) + Switzerland (EU–CH air transport agreement)
    /// + EU outermost regions that carry their own ISO code in airport data
    /// (Guadeloupe, Martinique, French Guiana, Réunion, Mayotte, Saint-Martin).
    /// Canary Islands, Madeira and the Azores are reported as ES/PT and are already covered.
    /// Not covered: Faroe Islands (FO), Greenland (GL), overseas countries/territories (PF, NC, PM, BL, AW, CW…).
    static let eu261Countries: Set<String> = [
        "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE",
        "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE",
        "IS", "NO", "LI", "CH",
        "GP", "MQ", "GF", "RE", "YT", "MF"
    ]

    /// Countries where UK261 applies to departing flights (Great Britain + Northern Ireland).
    /// Channel Islands (GG, JE) and the Isle of Man (IM) are outside UK261.
    static let uk261Countries: Set<String> = ["GB"]

    /// IATA codes of carriers holding an EU/EEA/Swiss operating licence ("Community carriers").
    /// Group codes used by both EU and UK entities (easyJet U2, Wizz W6/W9) are listed in both sets.
    /// Keep this list maintained: an airline missing here is only a problem for flights
    /// that *arrive* in the EU from outside (departures from the EU are covered for any airline).
    static let euCarriers: Set<String> = [
        // Austria
        "OS", "EC",
        // Belgium
        "SN", "TB",
        // Bulgaria
        "FB",
        // Croatia
        "OU",
        // Cyprus
        "CY",
        // Czechia
        "OK", "QS",
        // Denmark / Scandinavia
        "SK", "DX",
        // Estonia, Latvia, Lithuania
        "BT",
        // Finland
        "AY",
        // France
        "AF", "TO", "SS", "TX", "BF", "XK", "A5", "UU",
        // Germany
        "LH", "EW", "DE", "X3", "4Y", "CL", "VL",
        // Greece
        "A3", "OA", "GQ",
        // Hungary
        "W6",
        // Ireland
        "EI", "FR",
        // Italy
        "AZ", "EN", "NO",
        // Luxembourg
        "LG", "CV",
        // Malta
        "KM", "AL", "W4", "LW",
        // Netherlands
        "KL", "HV", "OR", "WA",
        // Poland
        "LO", "E4",
        // Portugal
        "TP", "S4", "SP", "NI",
        // Romania
        "RO",
        // Spain
        "IB", "I2", "VY", "UX", "YW", "V7", "NT", "PM", "2W", "EB",
        // Norway / Iceland (EEA)
        "DY", "D8", "WF", "FI", "OG",
        // Switzerland
        "LX", "WK", "DS", "2L",
        // easyJet group (EU entity easyJet Europe operates under the U2 marketing code)
        "U2"
    ]

    /// IATA codes of UK-licensed carriers.
    static let ukCarriers: Set<String> = [
        "BA", "VS", "U2", "LS", "BY", "LM", "T3", "W9", "RK", "MT", "ZT"
    ]

    static func isEUCarrier(_ iata: String) -> Bool { euCarriers.contains(iata.uppercased()) }
    static func isUKCarrier(_ iata: String) -> Bool { ukCarriers.contains(iata.uppercased()) }
    static func isEU261Country(_ iso: String) -> Bool { eu261Countries.contains(iso.uppercased()) }
    static func isUK261Country(_ iso: String) -> Bool { uk261Countries.contains(iso.uppercased()) }
}
