import Foundation
import SwiftData

enum StatusType: String, Codable {
    case arrived = "arrived"
    case leaving = "leaving"
    case onTheWay = "on_the_way"
    case pulse = "pulse"

    var displayText: String {
        switch self {
        case .arrived:
            return "Arrived"
        case .leaving:
            return "Leaving"
        case .onTheWay:
            return "On the way"
        case .pulse:
            return "Active"
        }
    }

    var icon: String {
        switch self {
        case .arrived:
            return "location.fill"
        case .leaving:
            return "arrow.right.circle.fill"
        case .onTheWay:
            return "car.fill"
        case .pulse:
            return "waveform.path.ecg"
        }
    }
}

enum TriggerType: String, Codable {
    case manual = "manual"
    case bluetooth = "bluetooth"
    case geofence = "geofence"
    case hourly = "hourly"

    var displayText: String {
        switch self {
        case .manual:
            return "Manual"
        case .bluetooth:
            return "Car Bluetooth"
        case .geofence:
            return "Location"
        case .hourly:
            return "Auto pulse"
        }
    }
}

@Model
final class PulseStatus {
    @Attribute(.unique) var id: UUID
    var serverID: UUID?  // ID from Supabase
    var userID: UUID
    var groupID: UUID
    var statusTypeRaw: String
    var triggerTypeRaw: String
    var locationName: String?
    var latitude: Double?
    var longitude: Double?
    var createdAt: Date

    // Computed properties
    var statusType: StatusType {
        get { StatusType(rawValue: statusTypeRaw) ?? .pulse }
        set { statusTypeRaw = newValue.rawValue }
    }

    var triggerType: TriggerType {
        get { TriggerType(rawValue: triggerTypeRaw) ?? .manual }
        set { triggerTypeRaw = newValue.rawValue }
    }

    // Relationships
    @Relationship(inverse: \UserProfile.statuses) var user: UserProfile?
    @Relationship(inverse: \Group.statuses) var group: Group?

    init(
        id: UUID = UUID(),
        serverID: UUID? = nil,
        userID: UUID,
        groupID: UUID,
        statusType: StatusType,
        triggerType: TriggerType = .manual,
        locationName: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.serverID = serverID
        self.userID = userID
        self.groupID = groupID
        self.statusTypeRaw = statusType.rawValue
        self.triggerTypeRaw = triggerType.rawValue
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
    }

    func relativeTimeText() -> String {
        let interval = Date().timeIntervalSince(createdAt)
        let minutes = Int(interval / 60)

        if minutes < 1 {
            return "Just now"
        } else if minutes < 60 {
            return "\(minutes)m ago"
        } else if minutes < 1440 {
            let hours = minutes / 60
            return "\(hours)h ago"
        } else {
            let days = minutes / 1440
            return "\(days)d ago"
        }
    }
}
