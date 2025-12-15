import Foundation

enum DelayType: String, Codable, Hashable {
    case delay
    case cancellation
}

struct DelayEvent: Codable, Equatable, Hashable, Identifiable {
    let id: UUID
    let type: DelayType
    let duration: TimeInterval // in seconds
    let actualTime: Date?
    let reason: String?
    
    init(id: UUID = UUID(), type: DelayType, duration: TimeInterval, actualTime: Date? = nil, reason: String? = nil) {
        self.id = id
        self.type = type
        self.duration = duration
        self.actualTime = actualTime
        self.reason = reason
    }
    
    var durationInHours: Double {
        duration / 3600.0
    }
    
    var formattedDuration: String {
        let hours = Int(durationInHours)
        let minutes = Int((durationInHours.truncatingRemainder(dividingBy: 1)) * 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}


