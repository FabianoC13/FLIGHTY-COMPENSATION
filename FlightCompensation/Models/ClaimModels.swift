import Foundation
import UIKit

// MARK: - Claim Models

struct ClaimRequest: Identifiable, Codable {
    let id: UUID
    let flightId: String
    var passengerDetails: PassengerDetails
    var evidence: ClaimEvidence
    var representationAuth: RepresentationAuth?
    var disruption: DisruptionReport
    var consents: ClaimConsents
    let createdAt: Date

    init(flightId: String) {
        self.id = UUID()
        self.flightId = flightId
        self.passengerDetails = PassengerDetails()
        self.evidence = ClaimEvidence()
        self.disruption = DisruptionReport()
        self.consents = ClaimConsents()
        self.createdAt = Date()
    }
}

struct PassengerDetails: Codable {
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var phoneNumber: String = ""
    var documentType: DocumentType = .dni
    var documentNumber: String = ""
    var address: Address = Address()
    /// Airline booking reference (PNR), printed on the booking confirmation. Airlines ask for it first.
    var bookingReference: String = ""
    /// Set when a parent or legal guardian claims for a passenger under 18.
    var minor: MinorPassenger?

    var isValid: Bool {
        !firstName.trimmed.isEmpty &&
        !lastName.trimmed.isEmpty &&
        email.isPlausibleEmail &&
        !documentNumber.trimmed.isEmpty &&
        bookingReference.trimmed.count >= 5 &&
        address.isValid &&
        (minor?.isValid ?? true)
    }

    /// Name of the person who travelled (the child, when claiming for a minor).
    var travellerFullName: String {
        if let minor { return "\(minor.firstName) \(minor.lastName)".trimmed }
        return "\(firstName) \(lastName)".trimmed
    }

    var signerFullName: String { "\(firstName) \(lastName)".trimmed }
}

/// A child passenger. The signer (`PassengerDetails` names) is the parent or guardian.
struct MinorPassenger: Codable, Equatable {
    enum Custody: String, Codable, CaseIterable, Identifiable {
        case sole = "Sole custody"
        case joint = "Joint custody"
        var id: String { rawValue }
    }

    var firstName: String = ""
    var lastName: String = ""
    var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -8, to: Date()) ?? Date()
    var relationship: String = "Parent"
    var custody: Custody = .joint
    /// With joint custody, the signer confirms the other parent/guardian agrees to the claim.
    var otherGuardianConsents: Bool = false

    var isValid: Bool {
        !firstName.trimmed.isEmpty && !lastName.trimmed.isEmpty && !relationship.trimmed.isEmpty &&
        (custody == .sole || otherGuardianConsents)
    }
}

enum DocumentType: String, Codable, CaseIterable, Identifiable {
    case dni = "DNI"
    case passport = "Passport"
    case nie = "NIE"

    var id: String { rawValue }
}

struct Address: Codable {
    var street: String = ""
    var city: String = ""
    var postalCode: String = ""
    var country: String = "Spain"

    var isValid: Bool {
        !street.trimmed.isEmpty && !city.trimmed.isEmpty && !postalCode.trimmed.isEmpty && !country.trimmed.isEmpty
    }

    var singleLine: String {
        [street, postalCode, city, country].map(\.trimmed).filter { !$0.isEmpty }.joined(separator: ", ")
    }
}

struct ClaimEvidence: Codable {
    var boardingPassImage: Data?
    var bookingConfirmationImage: Data?
    var identityDocumentImage: Data?

    // Images are uploaded to Storage, never persisted in JSON.
    enum CodingKeys: String, CodingKey {
        case hasBoardingPass
        case hasBookingConfirmation
        case hasIdentityDocument
    }

    init() {}

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(boardingPassImage != nil, forKey: .hasBoardingPass)
        try container.encode(bookingConfirmationImage != nil, forKey: .hasBookingConfirmation)
        try container.encode(identityDocumentImage != nil, forKey: .hasIdentityDocument)
    }

    init(from decoder: Decoder) throws {
        self.init()
    }

    /// Proof of travel: a boarding pass or the booking confirmation.
    var hasProofOfTravel: Bool {
        boardingPassImage != nil || bookingConfirmationImage != nil
    }

    /// Airlines and enforcement bodies ask for ID mainly to verify the signature on the authorisation.
    /// AESA (Spain) requires it for every complaint, so it's mandatory for escalations.
    func isComplete(requiresIdentityDocument: Bool) -> Bool {
        hasProofOfTravel && (!requiresIdentityDocument || identityDocumentImage != nil)
    }
}

struct RepresentationAuth: Codable {
    let signatureImage: Data // PNG data of the signature
    let signedDate: Date
    let signedLocation: String

    var isValid: Bool {
        !signatureImage.isEmpty
    }
}

// MARK: - What happened (passenger's answers)

/// Facts only the passenger knows, needed by the EU261 rules (`EU261Rules`).
struct DisruptionReport: Codable, Equatable {
    enum ArrivalDelay: String, Codable, CaseIterable, Identifiable {
        case underThreeHours = "Less than 3 hours late"
        case threeToFourHours = "3 to 4 hours late"
        case overFourHours = "More than 4 hours late"
        case neverArrived = "I never reached my destination"
        var id: String { rawValue }

        /// Representative minutes used by the rules for each answer.
        var minutes: Int {
            switch self {
            case .underThreeHours: return 150
            case .threeToFourHours: return 210
            case .overFourHours, .neverArrived: return 300
            }
        }
    }

    enum Notice: String, Codable, CaseIterable, Identifiable {
        case underSevenDays = "Less than 7 days before"
        case sevenToThirteenDays = "7 to 13 days before"
        case fourteenDaysOrMore = "14 days or more before"
        var id: String { rawValue }

        var days: Int {
            switch self {
            case .underSevenDays: return 3
            case .sevenToThirteenDays: return 10
            case .fourteenDaysOrMore: return 21
            }
        }
    }

    enum AlternativeDeparture: String, Codable, CaseIterable, Identifiable {
        case notEarlier = "Not earlier, or up to 1 hour earlier"
        case oneToTwoHoursEarlier = "1 to 2 hours earlier"
        case moreThanTwoHoursEarlier = "More than 2 hours earlier"
        var id: String { rawValue }

        var minutes: Int {
            switch self {
            case .notEarlier: return 0
            case .oneToTwoHoursEarlier: return 90
            case .moreThanTwoHoursEarlier: return 180
            }
        }
    }

    enum AlternativeArrival: String, Codable, CaseIterable, Identifiable {
        case underTwoHours = "Less than 2 hours late"
        case twoToThreeHours = "2 to 3 hours late"
        case threeToFourHours = "3 to 4 hours late"
        case overFourHours = "More than 4 hours late"
        var id: String { rawValue }

        var minutes: Int {
            switch self {
            case .underTwoHours: return 90
            case .twoToThreeHours: return 150
            case .threeToFourHours: return 210
            case .overFourHours: return 300
            }
        }
    }

    var arrivalDelay: ArrivalDelay?
    var notice: Notice?
    /// nil = not answered yet.
    var alternativeOffered: Bool?
    var alternativeDeparture: AlternativeDeparture = .notEarlier
    var alternativeArrival: AlternativeArrival = .overFourHours
    /// Reason the airline gave, if any.
    var airlineReason: String = ""
    /// The passenger already claimed or was paid by the airline (we can't take the case then).
    var alreadyCompensated: Bool = false
}

/// Local store for the passenger's answers, keyed by flight, so the eligibility card
/// on the flight screen reflects them too.
enum DisruptionReportStore {
    private static func key(_ flightId: UUID) -> String { "disruption_report_\(flightId.uuidString)" }

    static func load(for flightId: UUID) -> DisruptionReport? {
        guard let data = UserDefaults.standard.data(forKey: key(flightId)) else { return nil }
        return try? JSONDecoder().decode(DisruptionReport.self, from: data)
    }

    static func save(_ report: DisruptionReport, for flightId: UUID) {
        if let data = try? JSONEncoder().encode(report) {
            UserDefaults.standard.set(data, forKey: key(flightId))
        }
    }
}

// MARK: - Agreements and signature evidence

/// Versioned so we know which wording each passenger accepted.
enum ClaimDocumentVersion {
    static let current = "2026-10-v1"
}

struct ClaimConsents: Codable, Equatable {
    /// Service agreement incl. the success fee and 14-day withdrawal right.
    var acceptedTermsAndFee = false
    /// Assignment of claim + power of attorney (the signed authorisation).
    var acceptedAssignmentAndAuthority = false
    /// Privacy notice acknowledged (claim processing runs on the contract, not on consent).
    var acknowledgedPrivacy = false
    /// Passenger asks us to start before the 14-day withdrawal period ends.
    var requestedImmediateStart = false
    /// Information is true; no other company or lawyer is handling this claim.
    var confirmedTruthfulAndExclusive = false
    /// Optional, never pre-ticked.
    var marketingOptIn = false

    var allRequiredAccepted: Bool {
        acceptedTermsAndFee && acceptedAssignmentAndAuthority && acknowledgedPrivacy &&
        requestedImmediateStart && confirmedTruthfulAndExclusive
    }
}

/// Audit trail stored with the claim and printed on the signed PDF
/// (simple electronic signature under eIDAS Art. 25(1)).
struct SignatureAudit: Codable, Equatable {
    let signerName: String
    let signerEmail: String
    let signerUserId: String
    let signedAt: Date
    let timeZone: String
    let device: String
    let appVersion: String
    let documentVersion: String
    /// SHA-256 of the agreement text the passenger saw and accepted.
    let contentSHA256: String
    /// SHA-256 of the final signed PDF.
    var documentSHA256: String = ""
}

// MARK: - Helpers

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    var isPlausibleEmail: Bool {
        range(of: #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#, options: .regularExpression) != nil
    }
}
