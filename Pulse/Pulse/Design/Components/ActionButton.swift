import SwiftUI

// MARK: - Action Button
// Large, prominent button for primary actions

struct ActionButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var style: ActionButtonStyle
    var size: ActionButtonSize
    var isLoading: Bool
    var isDisabled: Bool

    init(
        _ title: String,
        icon: String? = nil,
        style: ActionButtonStyle = .primary,
        size: ActionButtonSize = .large,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(style.foregroundColor)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: size.iconSize, weight: .semibold))
                    }

                    Text(title)
                        .font(size.font)
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(style.foregroundColor)
            .frame(maxWidth: size == .large ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(style.backgroundColor)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .shadow(style.shadow)
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

// MARK: - Button Styles

enum ActionButtonStyle {
    case primary
    case secondary
    case destructive
    case ghost

    var backgroundColor: Color {
        switch self {
        case .primary:
            return DesignSystem.Colors.primary
        case .secondary:
            return DesignSystem.Colors.secondaryBackground
        case .destructive:
            return DesignSystem.Colors.error
        case .ghost:
            return Color.clear
        }
    }

    var foregroundColor: Color {
        switch self {
        case .primary, .destructive:
            return .white
        case .secondary:
            return DesignSystem.Colors.label
        case .ghost:
            return DesignSystem.Colors.primary
        }
    }

    var shadow: DesignSystem.Shadow.ShadowStyle {
        switch self {
        case .primary, .destructive:
            return DesignSystem.Shadow.medium
        case .secondary:
            return DesignSystem.Shadow.subtle
        case .ghost:
            return DesignSystem.Shadow.ShadowStyle(
                color: .clear,
                radius: 0,
                x: 0,
                y: 0
            )
        }
    }
}

// MARK: - Button Sizes

enum ActionButtonSize {
    case small
    case medium
    case large

    var height: CGFloat {
        switch self {
        case .small:
            return 36
        case .medium:
            return 44
        case .large:
            return 56
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small:
            return DesignSystem.Spacing.sm
        case .medium:
            return DesignSystem.Spacing.md
        case .large:
            return DesignSystem.Spacing.lg
        }
    }

    var font: Font {
        switch self {
        case .small:
            return DesignSystem.Typography.callout(.semibold)
        case .medium:
            return DesignSystem.Typography.body(.semibold)
        case .large:
            return DesignSystem.Typography.headline(.semibold)
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small:
            return DesignSystem.IconSize.small
        case .medium:
            return DesignSystem.IconSize.medium
        case .large:
            return DesignSystem.IconSize.large
        }
    }
}

// MARK: - Icon Button
// Circular button with icon only

struct IconButton: View {
    let icon: String
    let action: () -> Void
    var style: IconButtonStyle
    var size: IconButtonSize

    init(
        icon: String,
        style: IconButtonStyle = .primary,
        size: IconButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.action = action
        self.style = style
        self.size = size
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size.iconSize, weight: .semibold))
                .foregroundColor(style.foregroundColor)
                .frame(width: size.diameter, height: size.diameter)
                .background(style.backgroundColor)
                .clipShape(Circle())
                .shadow(style.shadow)
        }
    }
}

// MARK: - Icon Button Styles

enum IconButtonStyle {
    case primary
    case secondary
    case ghost

    var backgroundColor: Color {
        switch self {
        case .primary:
            return DesignSystem.Colors.primary
        case .secondary:
            return DesignSystem.Colors.secondaryBackground
        case .ghost:
            return Color.clear
        }
    }

    var foregroundColor: Color {
        switch self {
        case .primary:
            return .white
        case .secondary:
            return DesignSystem.Colors.label
        case .ghost:
            return DesignSystem.Colors.primary
        }
    }

    var shadow: DesignSystem.Shadow.ShadowStyle {
        switch self {
        case .primary:
            return DesignSystem.Shadow.medium
        case .secondary:
            return DesignSystem.Shadow.subtle
        case .ghost:
            return DesignSystem.Shadow.ShadowStyle(
                color: .clear,
                radius: 0,
                x: 0,
                y: 0
            )
        }
    }
}

enum IconButtonSize {
    case small
    case medium
    case large

    var diameter: CGFloat {
        switch self {
        case .small:
            return 32
        case .medium:
            return 44
        case .large:
            return 56
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small:
            return DesignSystem.IconSize.small
        case .medium:
            return DesignSystem.IconSize.medium
        case .large:
            return DesignSystem.IconSize.large
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 24) {
        // Action Buttons
        VStack(spacing: 12) {
            ActionButton("Primary Action", icon: "checkmark") { }

            ActionButton("Secondary Action", icon: "star", style: .secondary) { }

            ActionButton("Destructive Action", icon: "trash", style: .destructive) { }

            ActionButton("Ghost Action", icon: "arrow.right", style: .ghost) { }

            ActionButton("Loading...", isLoading: true) { }

            ActionButton("Disabled", isDisabled: true) { }
        }

        Divider()

        // Icon Buttons
        HStack(spacing: 16) {
            IconButton(icon: "heart.fill") { }

            IconButton(icon: "message.fill", style: .secondary) { }

            IconButton(icon: "plus", style: .ghost) { }

            IconButton(icon: "mic.fill", size: .large) { }
        }
    }
    .padding()
}
