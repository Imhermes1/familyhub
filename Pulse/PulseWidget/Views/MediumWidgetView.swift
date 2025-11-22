import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: PulseTimelineEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(entry.groupName)
                    .font(.headline)
                Spacer()
                Text("\(entry.memberCount) members")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Member statuses
            ForEach(entry.members.prefix(2)) { member in
                HStack(spacing: 8) {
                    Text(member.emoji)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(member.locationName ?? member.statusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(member.minutesAgo)m")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Top task
            if let task = entry.topTasks.first {
                Divider()

                HStack {
                    Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(.secondary)
                    Text(task.title)
                        .font(.subheadline)
                    Spacer()
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 12) {
#if WIDGET_EXTENSION
                Button(intent: MarkSafeIntent()) {
                    Label("I am here", systemImage: "location.fill")
                        .font(.caption)
                }
                Spacer()
                Button(intent: RefreshPulseIntent()) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
#else
                Button(action: {}) {
                    Label("I am here", systemImage: "location.fill")
                        .font(.caption)
                }
                Spacer()
                Button(action: {}) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
#endif
            }
        }
        .padding()
    }
}

#Preview(as: .systemMedium) {
    PulseWidget()
} timeline: {
    PulseTimelineEntry.preview()
}
