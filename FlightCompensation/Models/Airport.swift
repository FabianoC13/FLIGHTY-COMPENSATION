import Foundation
import CoreLocation

struct Airport: Codable, Equatable, Hashable, Identifiable {
    let id: UUID
    let code: String
    let name: String
    let city: String
    let country: String
    let latitude: Double?
    let longitude: Double?
    
    init(id: UUID = UUID(), code: String, name: String, city: String, country: String, latitude: Double? = nil, longitude: Double? = nil) {
        self.id = id
        self.code = code
        self.name = name
        self.city = city
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
    }

    /// Compatibility initializer (no coordinates) — some compiled units reference this exact signature.
    init(id: UUID = UUID(), code: String, name: String, city: String, country: String) {
        self.init(id: id, code: code, name: name, city: city, country: country, latitude: nil, longitude: nil)
    }
    
    var displayName: String {
        "\(city) (\(code))"
    }
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}


