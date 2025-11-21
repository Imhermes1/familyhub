import SwiftUI

// MARK: - Group Switcher
// Horizontal carousel for switching between groups

struct GroupSwitcher: View {
    @EnvironmentObject var dataManager: PulseDataManager
    @EnvironmentObject var feedManager: FeedManager

    var body: some View {
        if let currentGroup = dataManager.currentGroup {
            // For now, just show current group as a button
            // TODO: Phase 4 - Show horizontal carousel when multi-group support is added
            Menu {
                Label(currentGroup.name, systemImage: "person.3.fill")

                Divider()

                Button {
                    // TODO: Navigate to group management
                } label: {
                    Label("Manage Groups", systemImage: "gearshape")
                }

                Button {
                    // TODO: Create new group
                } label: {
                    Label("Create Group", systemImage: "plus.circle")
                }
            } label: {
                GroupPill(
                    name: currentGroup.name,
                    emoji: "👨‍👩‍👧‍👦",
                    color: DesignSystem.Colors.family,
                    isActive: true
                )
            }
        } else {
            Button {
                // TODO: Navigate to group creation
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: DesignSystem.IconSize.small))

                    Text("Create Group")
                        .font(DesignSystem.Typography.callout(.semibold))
                }
                .foregroundColor(DesignSystem.Colors.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(DesignSystem.Colors.primaryLight)
                .cornerRadius(DesignSystem.CornerRadius.pill)
            }
        }
    }
}

// MARK: - Group Pill
// Pill-shaped button for a group

struct GroupPill: View {
    let name: String
    let emoji: String
    let color: Color
    var isActive: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: 14))

            Text(name)
                .font(DesignSystem.Typography.callout(.semibold))
                .lineLimit(1)
        }
        .foregroundColor(isActive ? .white : DesignSystem.Colors.label)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isActive ? color : DesignSystem.Colors.secondaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.pill)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.pill)
                .stroke(color.opacity(isActive ? 0 : 0.3), lineWidth: isActive ? 0 : 1)
        )
    }
}

// MARK: - Multi-Group Carousel (Future Phase 4)
// This will be used when we add multi-group support

struct MultiGroupCarousel: View {
    let groups: [GroupInfo]
    @Binding var selectedGroupID: UUID?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(groups) { group in
                    GroupPill(
                        name: group.name,
                        emoji: group.emoji,
                        color: group.color,
                        isActive: selectedGroupID == group.id
                    )
                    .onTapGesture {
                        withAnimation(DesignSystem.Animation.spring) {
                            selectedGroupID = group.id
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.screenPadding)
        }
    }
}

// MARK: - Group Info

struct GroupInfo: Identifiable {
    let id: UUID
    let name: String
    let emoji: String
    let color: Color
    let category: GroupCategory
}

// Group Category (matches Phase 4 plan)
enum GroupCategory: String, Codable {
    case family
    case friends
    case work
    case custom

    var defaultEmoji: String {
        switch self {
        case .family:
            return "👨‍👩‍👧‍👦"
        case .friends:
            return "🎉"
        case .work:
            return "💼"
        case .custom:
            return "⭐️"
        }
    }

    var defaultColor: Color {
        switch self {
        case .family:
            return DesignSystem.Colors.family
        case .friends:
            return DesignSystem.Colors.friends
        case .work:
            return DesignSystem.Colors.work
        case .custom:
            return DesignSystem.Colors.custom
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 24) {
        // Single group (current state)
        GroupSwitcher()
            .environmentObject(PulseDataManager.shared)
            .environmentObject(FeedManager())

        Divider()

        // Multiple groups (future Phase 4)
        MultiGroupCarousel(
            groups: [
                GroupInfo(id: UUID(), name: "Family", emoji: "👨‍👩‍👧‍👦", color: .red, category: .family),
                GroupInfo(id: UUID(), name: "Friends", emoji: "🎉", color: .blue, category: .friends),
                GroupInfo(id: UUID(), name: "Work", emoji: "💼", color: .green, category: .work),
                GroupInfo(id: UUID(), name: "Sports Team", emoji: "⚽️", color: .purple, category: .custom)
            ],
            selectedGroupID: .constant(UUID())
        )
    }
    .padding()
}
