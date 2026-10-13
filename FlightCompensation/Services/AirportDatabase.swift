import Foundation

/// Offline lookup of IATA airport → country + coordinates.
///
/// Data: `Resources/airports.json`, generated from OurAirports (public domain,
/// https://ourairports.com/data/). Format: `{"MAD":["ES",40.4934,-3.5722], ...}`.
/// Regenerate with `scripts/generate_airports.py`.
struct AirportDatabase {

    struct Entry: Equatable {
        let iata: String
        let countryCode: String
        let latitude: Double
        let longitude: Double
    }

    private let entries: [String: Entry]

    init(entries: [String: Entry]) {
        self.entries = entries
    }

    init(jsonData: Data) throws {
        let raw = try JSONSerialization.jsonObject(with: jsonData) as? [String: [Any]] ?? [:]
        var parsed: [String: Entry] = [:]
        parsed.reserveCapacity(raw.count)
        for (code, value) in raw {
            guard value.count == 3,
                  let country = value[0] as? String,
                  let lat = (value[1] as? NSNumber)?.doubleValue,
                  let lon = (value[2] as? NSNumber)?.doubleValue else { continue }
            parsed[code] = Entry(iata: code, countryCode: country, latitude: lat, longitude: lon)
        }
        self.entries = parsed
    }

    /// Database bundled with the app. Empty if the resource is missing.
    static let shared: AirportDatabase = {
        guard let url = Bundle.main.url(forResource: "airports", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let db = try? AirportDatabase(jsonData: data) else {
            return AirportDatabase(entries: [:])
        }
        return db
    }()

    var count: Int { entries.count }

    func lookup(_ iata: String) -> Entry? {
        entries[iata.trimmingCharacters(in: .whitespaces).uppercased()]
    }

    /// Great-circle distance in km (haversine), as required by Art. 7(4) of Regulation 261/2004.
    static func greatCircleDistanceKm(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadiusKm = 6371.0
        let phi1 = lat1 * .pi / 180
        let phi2 = lat2 * .pi / 180
        let dPhi = (lat2 - lat1) * .pi / 180
        let dLambda = (lon2 - lon1) * .pi / 180
        let a = sin(dPhi / 2) * sin(dPhi / 2) + cos(phi1) * cos(phi2) * sin(dLambda / 2) * sin(dLambda / 2)
        return earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}
