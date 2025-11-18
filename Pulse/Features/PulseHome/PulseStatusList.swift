import SwiftUI

struct PulseStatusList: View {
    let statuses: [PulseStatus]

    var groupedStatuses: [UUID: PulseStatus] {
        var latest: [UUID: PulseStatus] = [:]
        for status in statuses {
            if let existing = latest[status.userID] {
                if status.createdAt > existing.createdAt {
                    latest[status.userID] = status
                }
            } else {
                latest[status.userID] = status
            }
        }
        return latest
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Group Members")
                .font(.headline)
                .padding(.horizontal)

            // Standard List - NO GLASS on content
            List {
                ForEach(Array(groupedStatuses.values), id: \.userID) { status in
                    MemberStatusRow(status: status)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
            .listStyle(.plain)
            .frame(minHeight: 200)
        }
    }
}

#Preview {
    PulseStatusList(statuses: [
        PulseStatus(
            userID: UUID(),
            groupID: UUID(),
            statusType: .arrived,
            locationName: "Home"
        ),
        PulseStatus(
            userID: UUID(),
            groupID: UUID(),
            statusType: .onTheWay,
            createdAt: Date().addingTimeInterval(-600)
        )
    ])
}
