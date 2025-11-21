import SwiftUI

// MARK: - Hero Status Card
// Large card showing all group members with live status

struct HeroStatusCard: View {
    @EnvironmentObject var dataManager: PulseDataManager
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency

    var onTapGesture: ((UUID) -> Void)?

    var glassVariant: Glass {
        reduceTransparency ? .identity : .regular
    }

    var body: some View {
        Card.prominent {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                // Group header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dataManager.currentGroup?.name ?? "My Group")
                            .font(DesignSystem.Typography.title3(.bold))

                        if let memberCount = dataManager.currentGroup?.memberCount {
                            Text("\(memberCount) \(memberCount == 1 ? "member" : "members")")
                                .font(DesignSystem.Typography.caption1())
                                .foregroundColor(DesignSystem.Colors.secondaryLabel)
                        }
                    }

                    Spacer()

                    // Automation status indicator
                    if let automationEnabled = dataManager.currentUser?.isAutomationEnabled(), automationEnabled {
                        StatusBadge(
                            status: .online,
                            text: "Auto",
                            showIndicator: true
                        )
                    }
                }

                // Member status carousel
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.lg) {
                        ForEach(memberStatuses, id: \.memberID) { memberStatus in
                            MemberStatusPill(
                                emoji: memberStatus.emoji,
                                name: memberStatus.name,
                                location: memberStatus.location,
                                isOnline: memberStatus.isOnline,
                                lastSeen: memberStatus.lastSeen
                            )
                            .onTapGesture {
                                onTapGesture?(memberStatus.memberID)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Data Preparation

    private var memberStatuses: [MemberStatus] {
        guard let currentUser = dataManager.currentUser else {
            return []
        }

        // Get latest status for current user
        let userStatus = dataManager.statuses
            .filter { $0.userID == currentUser.id }
            .sorted { $0.createdAt > $1.createdAt }
            .first

        let isOnline = isRecentStatus(userStatus?.createdAt)
        let location = userStatus?.locationName ?? userStatus?.statusType.displayName

        let memberStatus = MemberStatus(
            memberID: currentUser.id,
            emoji: currentUser.emoji,
            name: currentUser.displayName,
            location: location,
            isOnline: isOnline,
            lastSeen: userStatus?.createdAt
        )

        // TODO: Add other group members when we have proper member management
        return [memberStatus]
    }

    private func isRecentStatus(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        let fiveMinutesAgo = Date().addingTimeInterval(-5 * 60)
        return date > fiveMinutesAgo
    }
}

// MARK: - Member Status

struct MemberStatus {
    let memberID: UUID
    let emoji: String
    let name: String
    let location: String?
    let isOnline: Bool
    let lastSeen: Date?
}

// MARK: - Member Status Pill

struct MemberStatusPill: View {
    let emoji: String
    let name: String
    let location: String?
    let isOnline: Bool
    let lastSeen: Date?

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            // Avatar with status
            AvatarView(
                emoji: emoji,
                size: .large,
                showStatus: true,
                status: isOnline ? .online : .offline
            )

            // Name
            Text(name)
                .font(DesignSystem.Typography.callout(.semibold))
                .foregroundColor(DesignSystem.Colors.label)
                .lineLimit(1)

            // Location or last seen
            if let location = location {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(isOnline ? DesignSystem.Colors.success : DesignSystem.Colors.secondaryLabel)

                    Text(location)
                        .font(DesignSystem.Typography.caption1())
                        .foregroundColor(DesignSystem.Colors.secondaryLabel)
                        .lineLimit(1)
                }
            } else if let lastSeen = lastSeen {
                Text(timeAgo(lastSeen))
                    .font(DesignSystem.Typography.caption2())
                    .foregroundColor(DesignSystem.Colors.tertiaryLabel)
            } else {
                Text("—")
                    .font(DesignSystem.Typography.caption2())
                    .foregroundColor(DesignSystem.Colors.tertiaryLabel)
            }
        }
        .frame(width: 90)
    }

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview
#Preview {
    HeroStatusCard()
        .environmentObject(PulseDataManager.shared)
        .padding()
}
