import SwiftUI

// MARK: - Empty State
// Beautiful empty state with icon, title, message, and optional action

struct EmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 64, weight: .light))
                .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                .padding(.bottom, DesignSystem.Spacing.sm)

            // Text content
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.title2(.semibold))
                    .foregroundColor(DesignSystem.Colors.label)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Action button
            if let actionTitle = actionTitle, let action = action {
                ActionButton(
                    actionTitle,
                    size: .medium,
                    action: action
                )
                .padding(.top, DesignSystem.Spacing.sm)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(maxWidth: 400)
    }
}

// MARK: - Common Empty States

extension EmptyState {
    // No activity in feed
    static func noActivity(action: @escaping () -> Void) -> EmptyState {
        EmptyState(
            icon: "sparkles",
            title: "No Activity Yet",
            message: "Share your first update with your group to get started!",
            actionTitle: "Check In",
            action: action
        )
    }

    // No groups
    static func noGroups(action: @escaping () -> Void) -> EmptyState {
        EmptyState(
            icon: "person.3",
            title: "No Groups",
            message: "Create your first group or join an existing one to start staying connected.",
            actionTitle: "Create Group",
            action: action
        )
    }

    // No members
    static func noMembers(action: @escaping () -> Void) -> EmptyState {
        EmptyState(
            icon: "person.badge.plus",
            title: "Invite Members",
            message: "Your group is empty. Invite family and friends to start sharing updates.",
            actionTitle: "Invite People",
            action: action
        )
    }

    // No tasks
    static func noTasks(action: @escaping () -> Void) -> EmptyState {
        EmptyState(
            icon: "checkmark.circle",
            title: "No Tasks",
            message: "Add tasks to keep track of what needs to get done.",
            actionTitle: "Add Task",
            action: action
        )
    }

    // No notes
    static func noNotes(action: @escaping () -> Void) -> EmptyState {
        EmptyState(
            icon: "note.text",
            title: "No Notes",
            message: "Capture quick thoughts and share them with your group.",
            actionTitle: "Add Note",
            action: action
        )
    }

    // No photos
    static func noPhotos(action: @escaping () -> Void) -> EmptyState {
        EmptyState(
            icon: "photo.on.rectangle",
            title: "No Photos",
            message: "Share moments from your day with quick photo updates.",
            actionTitle: "Take Photo",
            action: action
        )
    }

    // No voice messages
    static func noVoiceMessages(action: @escaping () -> Void) -> EmptyState {
        EmptyState(
            icon: "waveform",
            title: "No Voice Messages",
            message: "Send quick voice messages to stay connected on the go.",
            actionTitle: "Record Message",
            action: action
        )
    }

    // Search no results
    static func noSearchResults(query: String) -> EmptyState {
        EmptyState(
            icon: "magnifyingglass",
            title: "No Results",
            message: "We couldn't find anything matching \"\(query)\". Try a different search."
        )
    }

    // Network error
    static func networkError(action: @escaping () -> Void) -> EmptyState {
        EmptyState(
            icon: "wifi.slash",
            title: "Connection Error",
            message: "We're having trouble connecting. Check your internet and try again.",
            actionTitle: "Retry",
            action: action
        )
    }

    // Generic error
    static func error(message: String, action: @escaping () -> Void) -> EmptyState {
        EmptyState(
            icon: "exclamationmark.triangle",
            title: "Something Went Wrong",
            message: message,
            actionTitle: "Try Again",
            action: action
        )
    }
}

// MARK: - Loading State
// Skeleton loader for content

struct LoadingState: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonCard()
            }
        }
        .padding()
    }
}

struct SkeletonCard: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Header
            HStack {
                Circle()
                    .fill(DesignSystem.Colors.tertiaryBackground)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.tertiaryBackground)
                        .frame(width: 100, height: 12)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.tertiaryBackground)
                        .frame(width: 60, height: 10)
                }

                Spacer()
            }

            // Content lines
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.tertiaryBackground)
                    .frame(height: 10)

                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.tertiaryBackground)
                    .frame(width: 200, height: 10)
            }
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.large)
        .opacity(isAnimating ? 0.5 : 1.0)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        EmptyState.noActivity { }

        Divider()

        EmptyState.noGroups { }

        Divider()

        LoadingState()
    }
    .padding()
}
