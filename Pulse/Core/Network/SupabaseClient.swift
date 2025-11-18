import Foundation

/// Wrapper around Supabase Swift SDK
/// TODO: Install Supabase Swift SDK via SPM: https://github.com/supabase/supabase-swift
class SupabaseClient {
    private let supabaseURL: String
    private let supabaseAnonKey: String

    // TODO: Initialize actual Supabase client
    // private let client: SupabaseClient

    init() {
        // Load from plist
        guard let config = SupabaseConfig.load() else {
            fatalError("Supabase configuration not found")
        }

        self.supabaseURL = config.url
        self.supabaseAnonKey = config.anonKey

        // TODO: Initialize Supabase client
        // self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseAnonKey)
    }

    // MARK: - Authentication

    func isAuthenticated() async throws -> Bool {
        // TODO: Implement with Supabase Auth
        // return client.auth.session != nil
        return false
    }

    func signInWithMagicLink(email: String) async throws {
        // TODO: Implement
        // try await client.auth.signInWithOTP(email: email)
    }

    func signOut() async throws {
        // TODO: Implement
        // try await client.auth.signOut()
    }

    func getCurrentUserID() async throws -> UUID {
        // TODO: Implement
        // guard let user = client.auth.session?.user else {
        //     throw SupabaseError.notAuthenticated
        // }
        // return UUID(uuidString: user.id) ?? UUID()
        return UUID()
    }

    // MARK: - Database Operations

    func fetch<T: Decodable>(
        from table: String,
        matching query: [String: Any]? = nil
    ) async throws -> [T] {
        // TODO: Implement with Supabase Database
        // var request = client.database.from(table).select()
        // if let query = query {
        //     // Apply filters
        // }
        // return try await request.execute().value
        return []
    }

    func insert<T: Encodable>(
        into table: String,
        value: T
    ) async throws -> UUID {
        // TODO: Implement
        // let response = try await client.database.from(table).insert(value).execute()
        // return extractID(from: response)
        return UUID()
    }

    func update<T: Encodable>(
        table: String,
        id: UUID,
        value: T
    ) async throws {
        // TODO: Implement
        // try await client.database.from(table).update(value).eq("id", value: id).execute()
    }

    func delete(from table: String, id: UUID) async throws {
        // TODO: Implement
        // try await client.database.from(table).delete().eq("id", value: id).execute()
    }

    // MARK: - Realtime

    func subscribeToChannel(_ channelName: String) -> RealtimeChannel {
        // TODO: Implement
        // return client.realtime.channel(channelName)
        return RealtimeChannel()
    }
}

// MARK: - Configuration

struct SupabaseConfig {
    let url: String
    let anonKey: String

    static func load() -> SupabaseConfig? {
        guard let path = Bundle.main.path(forResource: "Supabase", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: String],
              let url = dict["SUPABASE_URL"],
              let anonKey = dict["SUPABASE_ANON_KEY"] else {
            return nil
        }

        return SupabaseConfig(url: url, anonKey: anonKey)
    }
}

// MARK: - Realtime Channel Stub

class RealtimeChannel {
    func on(_ event: String, callback: @escaping () -> Void) -> RealtimeChannel {
        // TODO: Implement
        return self
    }

    func subscribe() async {
        // TODO: Implement
    }

    func unsubscribe() async {
        // TODO: Implement
    }
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case notAuthenticated
    case networkError
    case decodingError

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .networkError:
            return "Network request failed"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}
