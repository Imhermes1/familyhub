import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
    let entry: PulseTimelineEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(entry.groupName)
                    .font(.headline)
                Spacer()
                Text("Updated \(entry.date.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // All members
            Text("Members")
                .font(.subheadline)
                .fontWeight(.semibold)

            ForEach(entry.members) { member in
                HStack(spacing: 8) {
                    Text(member.emoji)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.displayName)
                            .font(.subheadline)

                        Text(member.locationName ?? member.statusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(member.minutesAgo)m ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Tasks
            Text("Tasks")
                .font(.subheadline)
                .fontWeight(.semibold)

            ForEach(entry.topTasks.prefix(3)) { task in
                Button(intent: TickTaskIntent(taskID: task.id)) {
                    HStack {
                        Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(task.completed ? .green : .secondary)
                        Text(task.title)
                            .font(.subheadline)
                            .strikethrough(task.completed)
                        Spacer()
                    }
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 12) {
                Button(intent: MarkSafeIntent()) {
                    Label("I am here", systemImage: "location.fill")
                        .font(.caption)
                }
                Spacer()
                Button(intent: RefreshPulseIntent()) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .padding()
    }
}

#Preview(as: .systemLarge) {
    PulseWidget()
} timeline: {
    PulseTimelineEntry.preview()
}
