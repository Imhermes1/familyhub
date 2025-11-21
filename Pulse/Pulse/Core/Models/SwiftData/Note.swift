import Foundation
import SwiftData

enum NoteType: String, Codable {
    case text = "text"
    case drawing = "drawing"
}

@Model
final class Note {
    @Attribute(.unique) var id: UUID
    var serverID: UUID?  // ID from Supabase
    var groupID: UUID
    var userID: UUID
    var content: String
    var noteTypeRaw: String
    var drawingURL: String?  // Supabase Storage URL
    var createdAt: Date
    var updatedAt: Date

    // Computed property
    var noteType: NoteType {
        get { NoteType(rawValue: noteTypeRaw) ?? .text }
        set { noteTypeRaw = newValue.rawValue }
    }

    // Relationships
    @Relationship(inverse: \Group.notes) var group: Group?

    init(
        id: UUID = UUID(),
        serverID: UUID? = nil,
        groupID: UUID,
        userID: UUID,
        content: String,
        noteType: NoteType = .text,
        drawingURL: String? = nil
    ) {
        self.id = id
        self.serverID = serverID
        self.groupID = groupID
        self.userID = userID
        self.content = content
        self.noteTypeRaw = noteType.rawValue
        self.drawingURL = drawingURL
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
