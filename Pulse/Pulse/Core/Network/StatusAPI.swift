import Foundation

/// API for status_events table operations
class StatusAPI {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func createStatus(status: PulseStatus) async throws -> UUID {
        let dto = StatusEventDTO(
            userID: status.userID,
            groupID: status.groupID,
            statusType: status.statusType.rawValue,
            triggerType: status.triggerType.rawValue,
            locationName: status.locationName,
            latitude: status.latitude,
            longitude: status.longitude
        )

        return try await client.insert(into: "status_events", value: dto)
    }

    func fetchGroupStatuses(groupID: UUID, limit: Int = 50) async throws -> [PulseStatus] {
        // TODO: Implement with Supabase query
        // let dtos: [StatusEventDTO] = try await client.fetch(
        //     from: "status_events",
        //     matching: ["group_id": groupID.uuidString]
        // )
        // return dtos.map { dto in
        //     PulseStatus(from: dto)
        // }
        return []
    }

    func fetchUserStatuses(userID: UUID, limit: Int = 20) async throws -> [PulseStatus] {
        // TODO: Implement
        return []
    }
}
