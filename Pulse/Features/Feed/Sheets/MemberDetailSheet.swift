import SwiftUI

// MARK: - Member Detail Sheet
// Shows individual member's activity timeline

struct MemberDetailSheet: View {
    let memberID: UUID

    @EnvironmentObject var dataManager: PulseDataManager
    @EnvironmentObject var feedManager: FeedManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Member header
                    memberHeader
                        .padding(.top, DesignSystem.Spacing.md)

                    // Activity timeline
                    if memberFeedItems.isEmpty {
                        emptyState
                            .padding(.top, DesignSystem.Spacing.xxl)
                    } else {
                        activityTimeline
                    }
                }
                .padding(DesignSystem.Spacing.screenPadding)
            }
            .navigationTitle(memberName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Member Header

    private var memberHeader: some View {
        ProminentCard {
            VStack(spacing: DesignSystem.Spacing.md) {
                // Avatar
                AvatarView(
                    emoji: memberEmoji,
                    size: .xlarge,
                    showStatus: true,
                    status: isOnline ? .online : .offline
                )

                // Name
                Text(memberName)
                    .font(DesignSystem.Typography.title2(.bold))

                // Stats
                HStack(spacing: DesignSystem.Spacing.xl) {
                    StatItem(
                        icon: "location.fill",
                        value: "\(locationCount)",
                        label: "Locations"
                    )

                    StatItem(
                        icon: "checkmark.circle",
                        value: "\(taskCount)",
                        label: "Tasks"
                    )

                    StatItem(
                        icon: "note.text",
                        value: "\(noteCount)",
                        label: "Notes"
                    )
                }

                // Last seen or current status
                if let lastStatus = latestStatus {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: DesignSystem.IconSize.small))
                            .foregroundColor(DesignSystem.Colors.success)

                        Text(lastStatus.locationName ?? lastStatus.statusType.displayText)
                            .font(DesignSystem.Typography.body(.medium))

                        Text("•")
                            .font(DesignSystem.Typography.caption2())
                            .foregroundColor(DesignSystem.Colors.tertiaryLabel)

                        Text(timeAgo(lastStatus.createdAt))
                            .font(DesignSystem.Typography.caption1())
                            .foregroundColor(DesignSystem.Colors.secondaryLabel)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    // MARK: - Activity Timeline

    private var activityTimeline: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Recent Activity")
                .font(DesignSystem.Typography.headline(.semibold))
                .foregroundColor(DesignSystem.Colors.label)

            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(memberFeedItems) { item in
                    feedItemCard(for: item)
                }
            }
        }
    }

    @ViewBuilder
    private func feedItemCard(for item: FeedItem) -> some View {
        switch item.type {
        case .location(let status):
            LocationCard(
                status: status,
                userName: item.userName,
                userEmoji: item.userEmoji
            )

        case .task(let task):
            TaskCard(
                task: task,
                userName: item.userName,
                userEmoji: item.userEmoji,
                onToggle: { toggledTask in
                    Task {
                        try? await dataManager.toggleTask(toggledTask)
                    }
                }
            )

        case .note(let note):
            NoteCard(
                note: note,
                userName: item.userName,
                userEmoji: item.userEmoji
            )

        case .photo, .voiceMessage:
            EmptyView()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyState(
            icon: "sparkles",
            title: "No Activity Yet",
            message: "\(memberName) hasn't shared any updates recently."
        )
    }

    // MARK: - Computed Properties

    private var member: UserProfile? {
        // For now, only current user is available
        if dataManager.currentUser?.id == memberID {
            return dataManager.currentUser
        }
        return nil
    }

    private var memberName: String {
        member?.displayName ?? "Member"
    }

    private var memberEmoji: String {
        member?.emoji ?? "👤"
    }

    private var memberFeedItems: [FeedItem] {
        feedManager.getFeedItems(for: memberID)
    }

    private var latestStatus: PulseStatus? {
        dataManager.statuses
            .filter { $0.userID == memberID }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }

    private var isOnline: Bool {
        guard let lastStatus = latestStatus else { return false }
        let fiveMinutesAgo = Date().addingTimeInterval(-5 * 60)
        return lastStatus.createdAt > fiveMinutesAgo
    }

    private var locationCount: Int {
        memberFeedItems.filter {
            if case .location = $0.type { return true }
            return false
        }.count
    }

    private var taskCount: Int {
        memberFeedItems.filter {
            if case .task = $0.type { return true }
            return false
        }.count
    }

    private var noteCount: Int {
        memberFeedItems.filter {
            if case .note = $0.type { return true }
            return false
        }.count
    }

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: DesignSystem.IconSize.small))

                Text(value)
                    .font(DesignSystem.Typography.title3(.bold))
            }
            .foregroundColor(DesignSystem.Colors.primary)

            Text(label)
                .font(DesignSystem.Typography.caption1())
                .foregroundColor(DesignSystem.Colors.secondaryLabel)
        }
    }
}

// MARK: - UUID Identifiable Extension

extension UUID: Identifiable {
    public var id: UUID { self }
}

// MARK: - Preview
#Preview {
    MemberDetailSheet(memberID: UUID())
        .environmentObject(PulseDataManager.shared)
        .environmentObject(FeedManager())
}
