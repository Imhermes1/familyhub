import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var authUserID: UUID?
    var displayName: String
    var emoji: String
    var phoneNumber: String?
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade) var statuses: [PulseStatus]?
    @Relationship(deleteRule: .nullify) var createdTasks: [TaskItem]?
    @Relationship(deleteRule: .nullify) var assignedTasks: [TaskItem]?

    // Settings
    var bluetoothAutomation: Bool
    var geofenceAutomation: Bool
    var hourlyPulse: Bool
    var manualOnlyMode: Bool

    // Geofence locations
    var homeLatitude: Double?
    var homeLongitude: Double?
    var homeRadiusMeters: Int
    var workLatitude: Double?
    var workLongitude: Double?
    var workRadiusMeters: Int

    init(
        id: UUID = UUID(),
        authUserID: UUID? = nil,
        displayName: String,
        emoji: String = "👤",
        phoneNumber: String? = nil,
        bluetoothAutomation: Bool = false,
        geofenceAutomation: Bool = false,
        hourlyPulse: Bool = false,
        manualOnlyMode: Bool = false,
        homeRadiusMeters: Int = 100,
        workRadiusMeters: Int = 100
    ) {
        self.id = id
        self.authUserID = authUserID
        self.displayName = displayName
        self.emoji = emoji
        self.phoneNumber = phoneNumber
        self.createdAt = Date()
        self.updatedAt = Date()
        self.bluetoothAutomation = bluetoothAutomation
        self.geofenceAutomation = geofenceAutomation
        self.hourlyPulse = hourlyPulse
        self.manualOnlyMode = manualOnlyMode
        self.homeRadiusMeters = homeRadiusMeters
        self.workRadiusMeters = workRadiusMeters
    }

    func isAutomationEnabled() -> Bool {
        return !manualOnlyMode && (bluetoothAutomation || geofenceAutomation || hourlyPulse)
    }
}
