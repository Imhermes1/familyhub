import Foundation

/// Data Transfer Object for status_events table
struct StatusEventDTO: Codable {
    let userID: UUID
    let groupID: UUID
    let statusType: String
    let triggerType: String
    let locationName: String?
    let latitude: Double?
    let longitude: Double?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case groupID = "group_id"
        case statusType = "status_type"
        case triggerType = "trigger_type"
        case locationName = "location_name"
        case latitude
        case longitude
    }
}
