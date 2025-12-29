import Foundation

struct UserProfile: Codable {
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var phoneNumber: String = ""
    var documentType: DocumentType = .dni
    var documentNumber: String = ""
    var address: Address = Address()
    var signatureData: Data?
    
    var isValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty
    }
}
