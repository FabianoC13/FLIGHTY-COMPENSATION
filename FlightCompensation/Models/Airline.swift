import Foundation

struct Airline: Codable, Equatable, Hashable, Identifiable {
    let id: UUID
    let code: String
    let name: String
    let logoURL: String?
    
    init(id: UUID = UUID(), code: String, name: String, logoURL: String? = nil) {
        self.id = id
        self.code = code
        self.name = name
        self.logoURL = logoURL
    }
    
    var isEUAirline: Bool {
        // EU airline codes
        let euCodes = ["FR", "BA", "LH", "AF", "KL", "IB", "VY", "SN", "LX", "OS", "TP", "DY", "U2"]
        return euCodes.contains(code)
    }
    
}


