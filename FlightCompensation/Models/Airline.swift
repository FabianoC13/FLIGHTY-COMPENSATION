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

// MARK: - Branding
import SwiftUI

extension Airline {
    
    var brandColor: Color {
        // Map common airlines to their primary brand color
        switch code.uppercased() {
        case "LH", "DLH": // Lufthansa
            return Color(hex: "FFAE00") // Lufthansa Yellow
        case "BA", "BAW": // British Airways
            return Color(hex: "EB2226") // BA Red
        case "AF", "AFR": // Air France
            return Color(hex: "002157") // AF Navy
        case "KL", "KLM": // KLM
            return Color(hex: "00A1DE") // KLM Blue
        case "FR", "RYR": // Ryanair
            return Color(hex: "073590") // Ryanair Blue
        case "U2", "EZY": // EasyJet
            return Color(hex: "FF6600") // EasyJet Orange
        case "IB", "IBE": // Iberia
            return Color(hex: "D7192D") // Iberia Red
        case "VY", "VLG": // Vueling
            return Color(hex: "FFCC00") // Vueling Yellow
        case "LX", "SWR": // Swiss
            return Color(hex: "D52B1E") // Swiss Red
        case "UA", "UAL": // United
            return Color(hex: "005DAA") // United Blue
        case "AA", "AAL": // American
            return Color(hex: "C60C30") // AA Red/Blue
        case "DL", "DAL": // Delta
            return Color(hex: "E00427") // Delta Red
        case "EK", "UAE": // Emirates
            return Color(hex: "D71921") // Emirates Red
        case "QR", "QTR": // Qatar
            return Color(hex: "8D1B3D") // Qatar Burgundy
        default:
             return PremiumTheme.electricBlue
        }
    }
    
    var brandContentColor: Color {
        switch code.uppercased() {
        case "LH", "DLH", "VY", "VLG", "U2", "EZY":
            return .black // Dark text on bright backgrounds
        default:
            return .white // White text on dark/rich backgrounds
        }
    }
}



