import Foundation

/// Data Transfer Object for tasks table
struct TaskDTO: Codable {
    let groupID: UUID
    let createdBy: UUID
    let assignedTo: UUID?
    let title: String
    let completed: Bool
    let dueDate: Date?

    enum CodingKeys: String, CodingKey {
        case groupID = "group_id"
        case createdBy = "created_by"
        case assignedTo = "assigned_to"
        case title
        case completed
        case dueDate = "due_date"
    }
}

/// Data Transfer Object for groups table
struct GroupDTO: Codable {
    let name: String
    let inviteCode: String
    let createdBy: UUID

    enum CodingKeys: String, CodingKey {
        case name
        case inviteCode = "invite_code"
        case createdBy = "created_by"
    }
}

/// Data Transfer Object for group_members table
struct GroupMemberDTO: Codable {
    let groupID: UUID
    let userID: UUID
    let role: String

    enum CodingKeys: String, CodingKey {
        case groupID = "group_id"
        case userID = "user_id"
        case role
    }
}

/// Data Transfer Object for users table
struct UserDTO: Codable {
    let authUserID: UUID
    let displayName: String
    let emoji: String
    let phoneNumber: String?

    enum CodingKeys: String, CodingKey {
        case authUserID = "auth_user_id"
        case displayName = "display_name"
        case emoji
        case phoneNumber = "phone_number"
    }
}
