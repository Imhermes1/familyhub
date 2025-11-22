import SwiftUI

struct GroupSummaryCard: View {
    let group: Group?
    let automationEnabled: Bool
    let glassVariant: Glass

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(group?.name ?? "No Group")
                    .font(.headline)
                Spacer()
                if automationEnabled {
                    Label("Auto", systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Text("\(group?.memberCount ?? 0) members")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .glassEffect(glassVariant.tint(.blue))
    }
}

#Preview {
    GroupSummaryCard(
        group: Group(name: "My Family", inviteCode: "ABC123", memberCount: 4),
        automationEnabled: true,
        glassVariant: .regular
    )
    .padding()
}
