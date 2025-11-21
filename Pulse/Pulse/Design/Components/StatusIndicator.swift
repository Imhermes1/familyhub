import SwiftUI

// MARK: - Status Indicator
// Animated pulse indicator for live status

struct StatusIndicator: View {
    let status: UserStatus
    let size: StatusIndicatorSize
    var animated: Bool

    @State private var isPulsing = false

    init(
        status: UserStatus,
        size: StatusIndicatorSize = .medium,
        animated: Bool = true
    ) {
        self.status = status
        self.size = size
        self.animated = animated
    }

    var body: some View {
        ZStack {
            // Pulsing ring (only for online status)
            if status == .online && animated {
                Circle()
                    .fill(status.color.opacity(0.3))
                    .frame(width: size.outerDiameter, height: size.outerDiameter)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
                    .opacity(isPulsing ? 0 : 1)
            }

            // Solid indicator
            Circle()
                .fill(status.color)
                .frame(width: size.diameter, height: size.diameter)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: size.borderWidth)
                )
        }
        .onAppear {
            if status == .online && animated {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    isPulsing = true
                }
            }
        }
    }
}

// MARK: - Status Indicator Sizes

enum StatusIndicatorSize {
    case small
    case medium
    case large

    var diameter: CGFloat {
        switch self {
        case .small:
            return 8
        case .medium:
            return 12
        case .large:
            return 16
        }
    }

    var outerDiameter: CGFloat {
        diameter * 1.5
    }

    var borderWidth: CGFloat {
        switch self {
        case .small:
            return 1.5
        case .medium:
            return 2
        case .large:
            return 2.5
        }
    }
}

// MARK: - Status Badge
// Text badge with status indicator

struct StatusBadge: View {
    let status: UserStatus
    let text: String?
    var showIndicator: Bool

    init(
        status: UserStatus,
        text: String? = nil,
        showIndicator: Bool = true
    ) {
        self.status = status
        self.text = text ?? status.label
        self.showIndicator = showIndicator
    }

    var body: some View {
        HStack(spacing: 6) {
            if showIndicator {
                StatusIndicator(status: status, size: .small, animated: status == .online)
            }

            Text(text ?? "")
                .font(DesignSystem.Typography.caption1(.medium))
                .foregroundColor(DesignSystem.Colors.secondaryLabel)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.1))
        .cornerRadius(DesignSystem.CornerRadius.small)
    }
}

// MARK: - Live Indicator
// Simple "LIVE" badge with pulsing animation

struct LiveIndicator: View {
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .opacity(isPulsing ? 0.6 : 1.0)

            Text("LIVE")
                .font(DesignSystem.Typography.caption1(.bold))
                .foregroundColor(.red)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.red.opacity(0.1))
        .cornerRadius(DesignSystem.CornerRadius.small)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 32) {
        // Status indicators
        HStack(spacing: 24) {
            VStack {
                StatusIndicator(status: .online, size: .small)
                Text("Small")
                    .font(DesignSystem.Typography.caption2())
            }

            VStack {
                StatusIndicator(status: .online, size: .medium)
                Text("Medium")
                    .font(DesignSystem.Typography.caption2())
            }

            VStack {
                StatusIndicator(status: .online, size: .large)
                Text("Large")
                    .font(DesignSystem.Typography.caption2())
            }
        }

        Divider()

        // Different statuses
        HStack(spacing: 24) {
            VStack {
                StatusIndicator(status: .online)
                Text("Online")
                    .font(DesignSystem.Typography.caption2())
            }

            VStack {
                StatusIndicator(status: .away, animated: false)
                Text("Away")
                    .font(DesignSystem.Typography.caption2())
            }

            VStack {
                StatusIndicator(status: .offline, animated: false)
                Text("Offline")
                    .font(DesignSystem.Typography.caption2())
            }
        }

        Divider()

        // Status badges
        VStack(spacing: 12) {
            StatusBadge(status: .online)
            StatusBadge(status: .away)
            StatusBadge(status: .offline)
            StatusBadge(status: .online, text: "At Home", showIndicator: true)
        }

        Divider()

        // Live indicator
        LiveIndicator()
    }
    .padding()
}
