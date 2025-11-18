import Foundation
import SwiftData

@Model
final class TaskItem {
    @Attribute(.unique) var id: UUID
    var serverID: UUID?  // ID from Supabase
    var groupID: UUID
    var createdByUserID: UUID
    var assignedToUserID: UUID?
    var title: String
    var completed: Bool
    var completedAt: Date?
    var completedByUserID: UUID?
    var dueDate: Date?
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    @Relationship(inverse: \Group.tasks) var group: Group?
    @Relationship(inverse: \UserProfile.createdTasks) var createdBy: UserProfile?
    @Relationship(inverse: \UserProfile.assignedTasks) var assignedTo: UserProfile?

    init(
        id: UUID = UUID(),
        serverID: UUID? = nil,
        groupID: UUID,
        createdByUserID: UUID,
        assignedToUserID: UUID? = nil,
        title: String,
        completed: Bool = false,
        completedAt: Date? = nil,
        completedByUserID: UUID? = nil,
        dueDate: Date? = nil
    ) {
        self.id = id
        self.serverID = serverID
        self.groupID = groupID
        self.createdByUserID = createdByUserID
        self.assignedToUserID = assignedToUserID
        self.title = title
        self.completed = completed
        self.completedAt = completedAt
        self.completedByUserID = completedByUserID
        self.dueDate = dueDate
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    func toggle(completedBy: UUID) {
        completed.toggle()
        if completed {
            completedAt = Date()
            completedByUserID = completedBy
        } else {
            completedAt = nil
            completedByUserID = nil
        }
        updatedAt = Date()
    }
}
