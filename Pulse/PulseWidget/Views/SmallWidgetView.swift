import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: PulseTimelineEntry

    var myStatus: MemberStatus? {
        entry.members.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pulse")
                .font(.headline)

            Spacer()

            if let status = myStatus {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(status.emoji)
                        Text(status.statusText)
                            .font(.subheadline)
                    }

                    Text("\(status.minutesAgo)m ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("No updates")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(intent: MarkSafeIntent()) {
                Label("Check in", systemImage: "location.fill")
                    .font(.caption)
            }
        }
        .padding()
    }
}

#Preview(as: .systemSmall) {
    PulseWidget()
} timeline: {
    PulseTimelineEntry.preview()
}
