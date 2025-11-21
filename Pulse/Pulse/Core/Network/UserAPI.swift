import Foundation

/// API for users table operations
class UserAPI {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func createUser(profile: UserProfile) async throws -> UUID {
        let dto = UserDTO(
            authUserID: profile.authUserID!,
            displayName: profile.displayName,
            emoji: profile.emoji,
            phoneNumber: profile.phoneNumber
        )

        return try await client.insert(into: "users", value: dto)
    }

    func updateUser(profile: UserProfile) async throws {
        guard let authUserID = profile.authUserID else {
            throw UserAPIError.noAuthUserID
        }

        let dto = UserDTO(
            authUserID: authUserID,
            displayName: profile.displayName,
            emoji: profile.emoji,
            phoneNumber: profile.phoneNumber
        )

        try await client.update(table: "users", id: authUserID, value: dto)
    }

    func fetchUser(authUserID: UUID) async throws -> UserProfile {
        // TODO: Implement
        return UserProfile(displayName: "User")
    }

    func updateUserSettings(userID: UUID, settings: UserProfile) async throws {
        // TODO: Implement user_settings table operations
    }
}

enum UserAPIError: LocalizedError {
    case noAuthUserID

    var errorDescription: String? {
        switch self {
        case .noAuthUserID:
            return "User has no auth user ID"
        }
    }
}
