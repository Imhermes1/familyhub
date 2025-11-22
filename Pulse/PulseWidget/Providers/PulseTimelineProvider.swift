import Foundation
import WidgetKit

struct PulseTimelineProvider: TimelineProvider {
    private let appGroupStore = AppGroupStore()

    func placeholder(in context: Context) -> PulseTimelineEntry {
        PulseTimelineEntry.preview()
    }

    func getSnapshot(in context: Context, completion: @escaping (PulseTimelineEntry) -> Void) {
        if context.isPreview {
            completion(PulseTimelineEntry.preview())
        } else {
            let entry = loadEntry()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PulseTimelineEntry>) -> Void) {
        let entry = loadEntry()

        // Refresh every 5 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!

        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> PulseTimelineEntry {
        do {
            if let snapshot = try appGroupStore.readSnapshot() {
                return PulseTimelineEntry(
                    date: snapshot.lastUpdated,
                    groupName: snapshot.groupName,
                    memberCount: snapshot.memberCount,
                    members: snapshot.members.map {
                        WidgetMemberStatus(
                            id: $0.id,
                            displayName: $0.displayName,
                            emoji: $0.emoji,
                            statusType: $0.statusType,
                            statusText: $0.statusText,
                            locationName: $0.locationName,
                            timestamp: $0.timestamp,
                            minutesAgo: $0.minutesAgo
                        )
                    },
                    topTasks: snapshot.topTasks
                )
            }
        } catch {
            print("Failed to load widget data: \(error)")
        }

        // Fallback
        return PulseTimelineEntry(
            date: Date(),
            groupName: "No Data",
            memberCount: 0,
            members: [],
            topTasks: []
        )
    }
}
