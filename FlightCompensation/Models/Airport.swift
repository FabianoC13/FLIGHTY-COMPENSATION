import Foundation

struct Airport: Codable, Equatable, Hashable, Identifiable {
    let id: UUID
    let code: String
    let name: String
    let city: String
    let country: String
    
    init(id: UUID = UUID(), code: String, name: String, city: String, country: String) {
        self.id = id
        self.code = code
        self.name = name
        self.city = city
        self.country = country
    }
    
    var displayName: String {
        "\(city) (\(code))"
    }
}


