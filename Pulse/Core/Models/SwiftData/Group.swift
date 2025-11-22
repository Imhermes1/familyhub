import Foundation
import SwiftData

@Model
final class Group {
    @Attribute(.unique) var id: UUID
    var name: String
    var inviteCode: String
    var createdByUserID: UUID?
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade) var statuses: [PulseStatus]?
    @Relationship(deleteRule: .cascade) var tasks: [TaskItem]?
    @Relationship(deleteRule: .cascade) var notes: [Note]?

    // Cached member data (synced from Supabase)
    var memberIDs: [UUID]
    var memberCount: Int

    init(
        id: UUID = UUID(),
        name: String,
        inviteCode: String,
        createdByUserID: UUID? = nil,
        memberIDs: [UUID] = [],
        memberCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.inviteCode = inviteCode
        self.createdByUserID = createdByUserID
        self.createdAt = Date()
        self.updatedAt = Date()
        self.memberIDs = memberIDs
        self.memberCount = memberCount
    }
}
