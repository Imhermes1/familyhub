import Foundation
import SwiftUI

// MARK: - Feed Item
// Unified model for all activity feed items

struct FeedItem: Identifiable, Equatable {
    let id: UUID
    let type: FeedItemType
    let timestamp: Date
    let userID: UUID
    let groupID: UUID

    // User info for display
    var userName: String?
    var userEmoji: String?

    init(
        id: UUID = UUID(),
        type: FeedItemType,
        timestamp: Date,
        userID: UUID,
        groupID: UUID,
        userName: String? = nil,
        userEmoji: String? = nil
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.userID = userID
        self.groupID = groupID
        self.userName = userName
        self.userEmoji = userEmoji
    }

    // Equality based on ID only
    static func == (lhs: FeedItem, rhs: FeedItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Feed Item Type

enum FeedItemType: Equatable {
    case location(PulseStatus)
    case task(TaskItem)
    case note(Note)
    case photo(PhotoShare)      // Future Phase 3
    case voiceMessage(VoiceMessageModel) // Phase 2 - Now implemented!

    // Helper to get display icon
    var icon: String {
        switch self {
        case .location:
            return "location.fill"
        case .task:
            return "checkmark.circle"
        case .note:
            return "note.text"
        case .photo:
            return "photo"
        case .voiceMessage:
            return "waveform"
        }
    }

    // Helper to get type name
    var typeName: String {
        switch self {
        case .location:
            return "Location"
        case .task:
            return "Task"
        case .note:
            return "Note"
        case .photo:
            return "Photo"
        case .voiceMessage:
            return "Voice"
        }
    }

    // Equality for FeedItemType
    static func == (lhs: FeedItemType, rhs: FeedItemType) -> Bool {
        switch (lhs, rhs) {
        case (.location(let lStatus), .location(let rStatus)):
            return lStatus.id == rStatus.id
        case (.task(let lTask), .task(let rTask)):
            return lTask.id == rTask.id
        case (.note(let lNote), .note(let rNote)):
            return lNote.id == rNote.id
        case (.photo(let lPhoto), .photo(let rPhoto)):
            return lPhoto.id == rPhoto.id
        case (.voiceMessage(let lVoice), .voiceMessage(let rVoice)):
            return lVoice.id == rVoice.id
        default:
            return false
        }
    }
}

// MARK: - Temporary Placeholder Models for Future Features

// PhotoShare - Phase 3
struct PhotoShare: Identifiable, Equatable {
    let id: UUID
    var groupID: UUID
    var userID: UUID
    var photoURL: String?
    var thumbnailURL: String?
    var caption: String?
    var retentionPolicy: RetentionPolicy
    var expiresAt: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        groupID: UUID,
        userID: UUID,
        photoURL: String? = nil,
        thumbnailURL: String? = nil,
        caption: String? = nil,
        retentionPolicy: RetentionPolicy = .ephemeral24h,
        expiresAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.groupID = groupID
        self.userID = userID
        self.photoURL = photoURL
        self.thumbnailURL = thumbnailURL
        self.caption = caption
        self.retentionPolicy = retentionPolicy
        self.expiresAt = expiresAt
        self.createdAt = createdAt
    }
}

enum RetentionPolicy: String, Codable, Equatable {
    case ephemeral24h = "24h"
    case permanent = "permanent"

    var displayName: String {
        switch self {
        case .ephemeral24h:
            return "Delete after 24h"
        case .permanent:
            return "Keep forever"
        }
    }
}

// MARK: - Feed Item Extensions

extension FeedItem {
    // Create from existing models
    static func fromStatus(_ status: PulseStatus, userName: String?, userEmoji: String?) -> FeedItem {
        FeedItem(
            id: status.id,
            type: .location(status),
            timestamp: status.createdAt,
            userID: status.userID,
            groupID: status.groupID,
            userName: userName,
            userEmoji: userEmoji
        )
    }

    static func fromTask(_ task: TaskItem, userName: String?, userEmoji: String?) -> FeedItem {
        FeedItem(
            id: task.id,
            type: .task(task),
            timestamp: task.completedAt ?? task.dueDate ?? Date(),
            userID: task.createdByID,
            groupID: task.groupID,
            userName: userName,
            userEmoji: userEmoji
        )
    }

    static func fromNote(_ note: Note, userName: String?, userEmoji: String?) -> FeedItem {
        FeedItem(
            id: note.id,
            type: .note(note),
            timestamp: note.createdAt,
            userID: note.createdByID,
            groupID: note.groupID,
            userName: userName,
            userEmoji: userEmoji
        )
    }

    static func fromPhoto(_ photo: PhotoShare, userName: String?, userEmoji: String?) -> FeedItem {
        FeedItem(
            id: photo.id,
            type: .photo(photo),
            timestamp: photo.createdAt,
            userID: photo.userID,
            groupID: photo.groupID,
            userName: userName,
            userEmoji: userEmoji
        )
    }

    static func fromVoiceMessage(_ voice: VoiceMessageModel, userName: String?, userEmoji: String?) -> FeedItem {
        FeedItem(
            id: voice.id,
            type: .voiceMessage(voice),
            timestamp: voice.createdAt,
            userID: voice.senderID,
            groupID: voice.groupID,
            userName: userName,
            userEmoji: userEmoji
        )
    }
}

// MARK: - Feed Sorting

extension Array where Element == FeedItem {
    /// Sorts feed items by timestamp (newest first)
    func sortedByTime() -> [FeedItem] {
        self.sorted { $0.timestamp > $1.timestamp }
    }

    /// Filters by group ID
    func filtered(by groupID: UUID) -> [FeedItem] {
        self.filter { $0.groupID == groupID }
    }

    /// Filters by user ID
    func filtered(by userID: UUID) -> [FeedItem] {
        self.filter { $0.userID == userID }
    }

    /// Filters by type
    func filtered(by type: FeedItemTypeFilter) -> [FeedItem] {
        self.filter { item in
            switch (type, item.type) {
            case (.location, .location):
                return true
            case (.task, .task):
                return true
            case (.note, .note):
                return true
            case (.photo, .photo):
                return true
            case (.voiceMessage, .voiceMessage):
                return true
            case (.all, _):
                return true
            default:
                return false
            }
        }
    }
}

// MARK: - Feed Type Filter

enum FeedItemTypeFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case location = "Locations"
    case task = "Tasks"
    case note = "Notes"
    case photo = "Photos"
    case voiceMessage = "Voice"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all:
            return "square.grid.2x2"
        case .location:
            return "location.fill"
        case .task:
            return "checkmark.circle"
        case .note:
            return "note.text"
        case .photo:
            return "photo"
        case .voiceMessage:
            return "waveform"
        }
    }
}
