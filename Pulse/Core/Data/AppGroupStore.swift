import Foundation

/// Handles reading and writing data to the App Group container for widget access
class AppGroupStore {
    private let groupIdentifier = "group.com.yourcompany.pulse"
    private let snapshotFileName = "PulseSnapshot.json"
    private let lastRefreshFileName = "LastUpdate.txt"

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let containerURL: URL?

    init() {
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        self.containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: groupIdentifier
        )
    }

    // MARK: - Snapshot Operations

    func writeSnapshot(_ snapshot: PulseSnapshot) throws {
        guard let containerURL = containerURL else {
            throw AppGroupError.containerNotFound
        }

        let fileURL = containerURL.appendingPathComponent(snapshotFileName)
        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL, options: .atomic)
    }

    func readSnapshot() throws -> PulseSnapshot? {
        guard let containerURL = containerURL else {
            throw AppGroupError.containerNotFound
        }

        let fileURL = containerURL.appendingPathComponent(snapshotFileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(PulseSnapshot.self, from: data)
    }

    // MARK: - Last Refresh

    func updateLastRefresh(_ date: Date) {
        guard let containerURL = containerURL else { return }

        let fileURL = containerURL.appendingPathComponent(lastRefreshFileName)
        let dateString = ISO8601DateFormatter().string(from: date)

        try? dateString.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    func getLastRefresh() -> Date? {
        guard let containerURL = containerURL else { return nil }

        let fileURL = containerURL.appendingPathComponent(lastRefreshFileName)

        guard let dateString = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return nil
        }

        return ISO8601DateFormatter().date(from: dateString)
    }

    // MARK: - Cleanup

    func clearAll() throws {
        guard let containerURL = containerURL else {
            throw AppGroupError.containerNotFound
        }

        let snapshotURL = containerURL.appendingPathComponent(snapshotFileName)
        let refreshURL = containerURL.appendingPathComponent(lastRefreshFileName)

        try? FileManager.default.removeItem(at: snapshotURL)
        try? FileManager.default.removeItem(at: refreshURL)
    }
}

// MARK: - Models

struct PulseSnapshot: Codable {
    let groupName: String
    let memberCount: Int
    let lastUpdated: Date
    let members: [MemberStatus]
    let topTasks: [TaskSnapshot]

    init(groupName: String, memberCount: Int, lastUpdated: Date, members: [MemberStatus], topTasks: [TaskItem]) {
        self.groupName = groupName
        self.memberCount = memberCount
        self.lastUpdated = lastUpdated
        self.members = members
        self.topTasks = topTasks.map { TaskSnapshot(from: $0) }
    }
}

struct MemberStatus: Codable, Identifiable {
    let id: UUID
    let displayName: String
    let emoji: String
    let statusType: String
    let statusText: String
    let locationName: String?
    let timestamp: Date
    let minutesAgo: Int
}

struct TaskSnapshot: Codable, Identifiable {
    let id: UUID
    let title: String
    let completed: Bool
    let assignedTo: String?

    init(from task: TaskItem) {
        self.id = task.id
        self.title = task.title
        self.completed = task.completed
        self.assignedTo = nil  // TODO: Add user name lookup
    }
}

// MARK: - Errors

enum AppGroupError: LocalizedError {
    case containerNotFound
    case encodingFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .containerNotFound:
            return "App Group container not found"
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        }
    }
}
