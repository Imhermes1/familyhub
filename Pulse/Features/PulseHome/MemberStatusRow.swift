import SwiftUI

struct MemberStatusRow: View {
    let status: PulseStatus

    var body: some View {
        HStack(spacing: 12) {
            // Emoji avatar (placeholder)
            Text("👤")
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text("User")  // TODO: Fetch display name
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    Image(systemName: status.statusType.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(status.locationName ?? status.statusType.displayText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(status.relativeTimeText())
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        MemberStatusRow(
            status: PulseStatus(
                userID: UUID(),
                groupID: UUID(),
                statusType: .arrived,
                locationName: "Home"
            )
        )
        MemberStatusRow(
            status: PulseStatus(
                userID: UUID(),
                groupID: UUID(),
                statusType: .onTheWay,
                createdAt: Date().addingTimeInterval(-600)
            )
        )
    }
}
