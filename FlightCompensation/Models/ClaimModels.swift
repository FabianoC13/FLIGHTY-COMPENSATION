import Foundation
import UIKit

// MARK: - Claim Models

struct ClaimRequest: Identifiable, Codable {
    let id: UUID
    let flightId: String
    var passengerDetails: PassengerDetails
    var evidence: ClaimEvidence
    var representationAuth: RepresentationAuth?
    let createdAt: Date
    
    init(flightId: String) {
        self.id = UUID()
        self.flightId = flightId
        self.passengerDetails = PassengerDetails()
        self.evidence = ClaimEvidence()
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
    
    var isValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        !documentNumber.isEmpty &&
        address.isValid
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
        !street.isEmpty && !city.isEmpty && !postalCode.isEmpty && !country.isEmpty
    }
}

struct ClaimEvidence: Codable {
    // Storing as base64 strings or local file paths in a real app
    // For now, we'll keep it simple to indicate presence using Data for images
    var boardingPassImage: Data?
    var identityDocumentImage: Data?
    
    // Custom coding keys to skip Data if needed or handle large payloads differently
    enum CodingKeys: String, CodingKey {
        case hasBoardingPass
        case hasIdentityDocument
    }
    
    init() {}
    
    // Custom encoding to avoid storing massive image data in simple JSON logs if we want
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(boardingPassImage != nil, forKey: .hasBoardingPass)
        try container.encode(identityDocumentImage != nil, forKey: .hasIdentityDocument)
    }
    
    init(from decoder: Decoder) throws {
        // Mock init
        self.init()
    }
    
    var isComplete: Bool {
        boardingPassImage != nil && identityDocumentImage != nil
    }
}

struct RepresentationAuth: Codable {
    let signatureImage: Data // PNG data of the signature
    let signedDate: Date
    let signedLocation: String // e.g. "Madrid, Spain" (approximated or user entered)
    
    var isValid: Bool {
        !signatureImage.isEmpty
    }
}
