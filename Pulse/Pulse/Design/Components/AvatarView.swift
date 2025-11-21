import SwiftUI

// MARK: - Avatar View
// Circular avatar with emoji and optional status indicator

struct AvatarView: View {
    let emoji: String
    let size: AvatarSize
    var showStatus: Bool
    var status: UserStatus?
    var borderColor: Color?
    var borderWidth: CGFloat

    init(
        emoji: String,
        size: AvatarSize = .medium,
        showStatus: Bool = false,
        status: UserStatus? = nil,
        borderColor: Color? = nil,
        borderWidth: CGFloat = 0
    ) {
        self.emoji = emoji
        self.size = size
        self.showStatus = showStatus
        self.status = status
        self.borderColor = borderColor
        self.borderWidth = borderWidth
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Avatar circle
            Circle()
                .fill(DesignSystem.Colors.secondaryBackground)
                .overlay(
                    Text(emoji)
                        .font(.system(size: size.emojiSize))
                )
                .overlay(
                    Circle()
                        .stroke(borderColor ?? Color.clear, lineWidth: borderWidth)
                )
                .frame(width: size.diameter, height: size.diameter)

            // Status indicator
            if showStatus, let status = status {
                StatusIndicator(status: status, size: size.indicatorSize)
                    .offset(x: size.indicatorOffset, y: size.indicatorOffset)
            }
        }
    }
}

// MARK: - Avatar Sizes

enum AvatarSize {
    case small
    case medium
    case large
    case xlarge
    case hero

    var diameter: CGFloat {
        switch self {
        case .small:
            return DesignSystem.AvatarSize.small
        case .medium:
            return DesignSystem.AvatarSize.medium
        case .large:
            return DesignSystem.AvatarSize.large
        case .xlarge:
            return DesignSystem.AvatarSize.xlarge
        case .hero:
            return DesignSystem.AvatarSize.hero
        }
    }

    var emojiSize: CGFloat {
        diameter * 0.5  // Emoji is 50% of avatar size
    }

    var indicatorSize: StatusIndicatorSize {
        switch self {
        case .small:
            return .small
        case .medium:
            return .medium
        case .large, .xlarge, .hero:
            return .large
        }
    }

    var indicatorOffset: CGFloat {
        switch self {
        case .small:
            return 2
        case .medium:
            return 3
        case .large, .xlarge, .hero:
            return 4
        }
    }
}

// MARK: - User Status

enum UserStatus {
    case online
    case offline
    case away

    var color: Color {
        switch self {
        case .online:
            return DesignSystem.Colors.online
        case .offline:
            return DesignSystem.Colors.offline
        case .away:
            return DesignSystem.Colors.away
        }
    }

    var label: String {
        switch self {
        case .online:
            return "Online"
        case .offline:
            return "Offline"
        case .away:
            return "Away"
        }
    }
}

// MARK: - Avatar Group
// Multiple overlapping avatars

struct AvatarGroup: View {
    let emojis: [String]
    let size: AvatarSize
    var maxDisplay: Int
    var spacing: CGFloat

    init(
        emojis: [String],
        size: AvatarSize = .medium,
        maxDisplay: Int = 3,
        spacing: CGFloat = -8
    ) {
        self.emojis = emojis
        self.size = size
        self.maxDisplay = maxDisplay
        self.spacing = spacing
    }

    var displayEmojis: [String] {
        Array(emojis.prefix(maxDisplay))
    }

    var remainingCount: Int {
        max(0, emojis.count - maxDisplay)
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(Array(displayEmojis.enumerated()), id: \.offset) { index, emoji in
                AvatarView(
                    emoji: emoji,
                    size: size,
                    borderColor: DesignSystem.Colors.background,
                    borderWidth: 2
                )
                .zIndex(Double(displayEmojis.count - index))
            }

            if remainingCount > 0 {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.tertiaryBackground)
                        .frame(width: size.diameter, height: size.diameter)

                    Text("+\(remainingCount)")
                        .font(DesignSystem.Typography.caption1(.semibold))
                        .foregroundColor(DesignSystem.Colors.secondaryLabel)
                }
                .overlay(
                    Circle()
                        .stroke(DesignSystem.Colors.background, lineWidth: 2)
                )
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 32) {
        // Single avatars with different sizes
        HStack(spacing: 16) {
            AvatarView(emoji: "😊", size: .small)
            AvatarView(emoji: "👨", size: .medium)
            AvatarView(emoji: "👩", size: .large)
            AvatarView(emoji: "👶", size: .xlarge)
        }

        Divider()

        // Avatars with status indicators
        HStack(spacing: 16) {
            AvatarView(
                emoji: "😊",
                size: .medium,
                showStatus: true,
                status: .online
            )

            AvatarView(
                emoji: "👨",
                size: .medium,
                showStatus: true,
                status: .away
            )

            AvatarView(
                emoji: "👩",
                size: .medium,
                showStatus: true,
                status: .offline
            )
        }

        Divider()

        // Avatar groups
        VStack(spacing: 16) {
            AvatarGroup(emojis: ["😊", "👨", "👩"], size: .small)

            AvatarGroup(emojis: ["😊", "👨", "👩", "👶"], size: .medium)

            AvatarGroup(
                emojis: ["😊", "👨", "👩", "👶", "👧"],
                size: .large,
                maxDisplay: 3
            )
        }

        Divider()

        // Hero avatar
        AvatarView(
            emoji: "👨‍👩‍👧‍👦",
            size: .hero,
            showStatus: true,
            status: .online
        )
    }
    .padding()
}
