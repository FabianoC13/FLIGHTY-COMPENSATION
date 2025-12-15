import Foundation

enum FlightStatus: String, Codable, Equatable, Hashable {
    case scheduled
    case onTime
    case delayed
    case cancelled
    case departed
    case arrived
    
    var displayName: String {
        switch self {
        case .scheduled:
            return "Scheduled"
        case .onTime:
            return "On Time"
        case .delayed:
            return "Delayed"
        case .cancelled:
            return "Cancelled"
        case .departed:
            return "Departed"
        case .arrived:
            return "Arrived"
        }
    }
    
    var colorHex: String {
        switch self {
        case .scheduled, .onTime, .departed, .arrived:
            return "34C759" // Green
        case .delayed:
            return "FF9500" // Amber
        case .cancelled:
            return "FF3B30" // Red
        }
    }
}


