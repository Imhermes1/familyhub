import SwiftUI

// MARK: - Card Component
// Beautiful, minimal card container for content

struct Card<Content: View>: View {
    let content: Content
    var padding: CGFloat
    var cornerRadius: CGFloat
    var shadow: DesignSystem.Shadow.ShadowStyle
    var backgroundColor: Color
    var borderColor: Color?
    var borderWidth: CGFloat

    init(
        padding: CGFloat = DesignSystem.Spacing.cardPadding,
        cornerRadius: CGFloat = DesignSystem.CornerRadius.large,
        shadow: DesignSystem.Shadow.ShadowStyle = DesignSystem.Shadow.subtle,
        backgroundColor: Color = DesignSystem.Colors.cardBackground,
        borderColor: Color? = nil,
        borderWidth: CGFloat = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
    }

    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor ?? Color.clear, lineWidth: borderWidth)
            )
            .shadow(shadow)
    }
}

// MARK: - Card Variants (free functions for type inference)

func ProminentCard<Content: View>(
    @ViewBuilder content: () -> Content
) -> some View {
    Card(
        padding: DesignSystem.Spacing.md,
        cornerRadius: DesignSystem.CornerRadius.large,
        shadow: DesignSystem.Shadow.prominent,
        backgroundColor: DesignSystem.Colors.cardBackground,
        content: content
    )
}

func SubtleCard<Content: View>(
    @ViewBuilder content: () -> Content
) -> some View {
    Card(
        padding: DesignSystem.Spacing.md,
        cornerRadius: DesignSystem.CornerRadius.medium,
        shadow: DesignSystem.Shadow.subtle,
        backgroundColor: DesignSystem.Colors.cardBackground,
        content: content
    )
}

func BorderedCard<Content: View>(
    borderColor: Color = DesignSystem.Colors.cardBorder,
    @ViewBuilder content: () -> Content
) -> some View {
    Card(
        padding: DesignSystem.Spacing.md,
        cornerRadius: DesignSystem.CornerRadius.medium,
        shadow: DesignSystem.Shadow.ShadowStyle(
            color: .clear,
            radius: 0,
            x: 0,
            y: 0
        ),
        backgroundColor: DesignSystem.Colors.cardBackground,
        borderColor: borderColor,
        borderWidth: 1,
        content: content
    )
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Default Card")
                    .font(DesignSystem.Typography.headline())
                Text("This is a standard card with subtle shadow")
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
            }
        }

        ProminentCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Prominent Card")
                    .font(DesignSystem.Typography.headline())
                Text("This card has a stronger shadow")
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
            }
        }

        BorderedCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Bordered Card")
                    .font(DesignSystem.Typography.headline())
                Text("This card has a border instead of shadow")
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
            }
        }
    }
    .padding()
}
