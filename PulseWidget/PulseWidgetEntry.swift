import Foundation
import WidgetKit

struct PulseTimelineEntry: TimelineEntry {
    let date: Date
    let groupName: String
    let memberCount: Int
    let members: [MemberStatus]
    let topTasks: [TaskSnapshot]

    static func preview() -> PulseTimelineEntry {
        PulseTimelineEntry(
            date: Date(),
            groupName: "My Family",
            memberCount: 4,
            members: [
                MemberStatus(
                    id: UUID(),
                    displayName: "Mom",
                    emoji: "👩",
                    statusType: "arrived",
                    statusText: "At home",
                    locationName: "Home",
                    timestamp: Date().addingTimeInterval(-300),
                    minutesAgo: 5
                ),
                MemberStatus(
                    id: UUID(),
                    displayName: "Dad",
                    emoji: "👨",
                    statusType: "on_the_way",
                    statusText: "On the way",
                    locationName: nil,
                    timestamp: Date().addingTimeInterval(-720),
                    minutesAgo: 12
                ),
                MemberStatus(
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
