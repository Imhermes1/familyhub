import Foundation

/// API for groups and group_members table operations
class GroupAPI {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func createGroup(group: Group, creatorID: UUID) async throws -> UUID {
        let groupDTO = GroupDTO(
            name: group.name,
            inviteCode: group.inviteCode,
            createdBy: creatorID
        )

        let groupID = try await client.insert(into: "groups", value: groupDTO)

        // Add creator as first member
        let memberDTO = GroupMemberDTO(
            groupID: groupID,
            userID: creatorID,
            role: "admin"
        )
        _ = try await client.insert(into: "group_members", value: memberDTO)

        return groupID
    }

    func joinGroup(inviteCode: String, userID: UUID) async throws -> Group {
        // TODO: Implement
        // 1. Find group by invite code
        // 2. Add user to group_members
        // 3. Return group
        return Group(name: "Test Group", inviteCode: inviteCode)
    }

    func fetchGroup(groupID: UUID) async throws -> Group {
        // TODO: Implement
        return Group(name: "Test Group", inviteCode: "ABC123")
    }

    func fetchGroupMembers(groupID: UUID) async throws -> [UUID] {
        // TODO: Implement
        return []
    }

    func leaveGroup(groupID: UUID, userID: UUID) async throws {
        // TODO: Implement - delete from group_members
    }
}
