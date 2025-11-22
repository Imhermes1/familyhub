import Foundation
import WidgetKit

struct WidgetMemberStatus: Identifiable, Equatable {
    let id: UUID
    let displayName: String
    let emoji: String
    let statusType: String
    let statusText: String
    let locationName: String?
    let timestamp: Date
    let minutesAgo: Int
}

struct PulseTimelineEntry: TimelineEntry {
    let date: Date
    let groupName: String
    let memberCount: Int
    let members: [WidgetMemberStatus]
    let topTasks: [TaskSnapshot]

    static func preview() -> PulseTimelineEntry {
        PulseTimelineEntry(
            date: Date(),
            groupName: "My Family",
            memberCount: 4,
            members: [
                WidgetMemberStatus(
                    id: UUID(),
                    displayName: "Mom",
                    emoji: "👩",
                    statusType: "arrived",
                    statusText: "At home",
                    locationName: "Home",
                    timestamp: Date().addingTimeInterval(-300),
                    minutesAgo: 5
                ),
                WidgetMemberStatus(
                    id: UUID(),
                    displayName: "Dad",
                    emoji: "👨",
                    statusType: "on_the_way",
                    statusText: "On the way",
                    locationName: nil,
                    timestamp: Date().addingTimeInterval(-720),
                    minutesAgo: 12
                ),
                WidgetMemberStatus(
                    id: UUID(),
                    displayName: "Sister",
                    emoji: "👧",
                    statusType: "arrived",
                    statusText: "At work",
                    locationName: "Work",
                    timestamp: Date().addingTimeInterval(-3600),
                    minutesAgo: 60
                )
            ],
            topTasks: [
                TaskSnapshot(
                    id: UUID(),
                    title: "Buy groceries",
                    completed: false,
                    assignedTo: "Dad"
                )
            ]
        )
    }
}
