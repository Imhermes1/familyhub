import Foundation
import SwiftData

// MARK: - Voice Message Model
// SwiftData model for voice messages (walkie talkie feature)

@Model
class VoiceMessageModel {
    // MARK: - Properties

    @Attribute(.unique) var id: UUID
    var serverID: UUID? // Maps to Supabase database ID

    // Relationships
    var groupID: UUID
    var senderID: UUID
    var recipientIDs: [UUID] // Up to 4-5 recipients for small group PTT

    // Audio data
    var audioURL: String? // Supabase Storage URL
    var localFileURL: String? // Local cached file path
    var duration: TimeInterval
    var waveformData: Data? // Serialized waveform for visualization

    // Transcription
    var transcript: String?
    var transcriptLanguage: String?

    // Metadata
    var createdAt: Date
    var isPlayed: Bool
    var playedAt: Date?

    // Upload status
    var uploadStatus: UploadStatus
    var uploadProgress: Double

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        serverID: UUID? = nil,
        groupID: UUID,
        senderID: UUID,
        recipientIDs: [UUID] = [],
        audioURL: String? = nil,
        localFileURL: String? = nil,
        duration: TimeInterval = 0,
        waveformData: Data? = nil,
        transcript: String? = nil,
        transcriptLanguage: String? = nil,
        createdAt: Date = Date(),
        isPlayed: Bool = false,
        playedAt: Date? = nil,
        uploadStatus: UploadStatus = .pending,
        uploadProgress: Double = 0
    ) {
        self.id = id
        self.serverID = serverID
        self.groupID = groupID
        self.senderID = senderID
        self.recipientIDs = recipientIDs
        self.audioURL = audioURL
        self.localFileURL = localFileURL
        self.duration = duration
        self.waveformData = waveformData
        self.transcript = transcript
        self.transcriptLanguage = transcriptLanguage
        self.createdAt = createdAt
        self.isPlayed = isPlayed
        self.playedAt = playedAt
        self.uploadStatus = uploadStatus
        self.uploadProgress = uploadProgress
    }
}

// MARK: - Upload Status

enum UploadStatus: String, Codable {
    case pending = "pending"
    case uploading = "uploading"
    case completed = "completed"
    case failed = "failed"

    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .uploading:
            return "Uploading..."
        case .completed:
            return "Sent"
        case .failed:
            return "Failed"
        }
    }

    var icon: String {
        switch self {
        case .pending:
            return "clock"
        case .uploading:
            return "arrow.up.circle"
        case .completed:
            return "checkmark.circle"
        case .failed:
            return "exclamationmark.circle"
        }
    }
}

// MARK: - Computed Properties

extension VoiceMessageModel {
    /// Get file URL (prefer local, fallback to remote)
    var fileURL: URL? {
        if let localPath = localFileURL,
           FileManager.default.fileExists(atPath: localPath) {
            return URL(fileURLWithPath: localPath)
        }

        if let remoteURL = audioURL {
            return URL(string: remoteURL)
        }

        return nil
    }

    /// Check if message is ready to play
    var canPlay: Bool {
        return fileURL != nil && uploadStatus == .completed
    }

    /// Check if message was sent by current user
    func isSentByUser(_ userID: UUID) -> Bool {
        return senderID == userID
    }

    /// Check if message was sent to specific user
    func isSentToUser(_ userID: UUID) -> Bool {
        return recipientIDs.contains(userID)
    }

    /// Formatted duration (e.g., "0:45", "2:30")
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Time ago string
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - Audio Processing

extension VoiceMessageModel {
    /// Save local audio file
    func saveLocalFile(from sourceURL: URL) throws {
        let fileName = "voice_\(id.uuidString).m4a"
        let destinationURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VoiceMessages")
            .appendingPathComponent(fileName)

        // Create directory if needed
        let directory = destinationURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        // Copy file
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

        localFileURL = destinationURL.path
    }

    /// Delete local audio file
    func deleteLocalFile() {
        guard let localPath = localFileURL else { return }
        let url = URL(fileURLWithPath: localPath)
        try? FileManager.default.removeItem(at: url)
        localFileURL = nil
    }

    /// Generate waveform data from audio file
    func generateWaveform() async -> [Float]? {
        guard let url = fileURL else { return nil }

        // TODO: Implement waveform generation using AVAudioFile
        // For now, return placeholder data
        return Array(repeating: 0.5, count: 50)
    }
}

// MARK: - Identifiable Conformance

extension VoiceMessageModel: Identifiable {}
