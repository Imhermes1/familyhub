import SwiftUI

// MARK: - FamilyHub Design System
// Minimal, beautiful design language for world-class UX

enum DesignSystem {

    // MARK: - Typography
    enum Typography {
        // Display - Hero text
        static func display(_ weight: Font.Weight = .bold) -> Font {
            .system(size: 34, weight: weight, design: .rounded)
        }

        // Titles
        static func title1(_ weight: Font.Weight = .bold) -> Font {
            .system(size: 28, weight: weight, design: .rounded)
        }

        static func title2(_ weight: Font.Weight = .semibold) -> Font {
            .system(size: 22, weight: weight, design: .rounded)
        }

        static func title3(_ weight: Font.Weight = .semibold) -> Font {
            .system(size: 20, weight: weight, design: .rounded)
        }

        // Body
        static func headline(_ weight: Font.Weight = .semibold) -> Font {
            .system(size: 17, weight: weight, design: .default)
        }

        static func body(_ weight: Font.Weight = .regular) -> Font {
            .system(size: 17, weight: weight, design: .default)
        }

        static func callout(_ weight: Font.Weight = .regular) -> Font {
            .system(size: 16, weight: weight, design: .default)
        }

        static func subheadline(_ weight: Font.Weight = .regular) -> Font {
            .system(size: 15, weight: weight, design: .default)
        }

        // Small text
        static func footnote(_ weight: Font.Weight = .regular) -> Font {
            .system(size: 13, weight: weight, design: .default)
        }

        static func caption1(_ weight: Font.Weight = .regular) -> Font {
            .system(size: 12, weight: weight, design: .default)
        }

        static func caption2(_ weight: Font.Weight = .regular) -> Font {
            .system(size: 11, weight: weight, design: .default)
        }
    }

    // MARK: - Colors
    enum Colors {
        // Primary brand colors
        static let primary = Color.blue
        static let primaryLight = Color.blue.opacity(0.1)
        static let primaryDark = Color.blue.opacity(0.8)

        // Secondary colors
        static let secondary = Color.purple
        static let accent = Color.pink

        // Status colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue

        // Semantic colors
        static let online = Color.green
        static let offline = Color.gray
        static let away = Color.orange

        // Group category colors
        static let family = Color.red
        static let friends = Color.blue
        static let work = Color.green
        static let custom = Color.purple

        // Neutral colors
        static let background = Color(uiColor: .systemBackground)
        static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
        static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)

        static let label = Color(uiColor: .label)
        static let secondaryLabel = Color(uiColor: .secondaryLabel)
        static let tertiaryLabel = Color(uiColor: .tertiaryLabel)

        static let separator = Color(uiColor: .separator)

        // Card colors
        static let cardBackground = Color(uiColor: .secondarySystemBackground)
        static let cardBorder = Color(uiColor: .separator)
    }

    // MARK: - Spacing
    enum Spacing {
        // 4pt grid system
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64

        // Common padding presets
        static let cardPadding: CGFloat = md
        static let screenPadding: CGFloat = md
        static let sectionSpacing: CGFloat = lg
        static let itemSpacing: CGFloat = xs
    }

    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 24
        static let pill: CGFloat = 999  // For pill-shaped buttons
    }

    // MARK: - Shadows
    enum Shadow {
        static let subtle = ShadowStyle(
            color: Color.black.opacity(0.05),
            radius: 4,
            x: 0,
            y: 2
        )

        static let medium = ShadowStyle(
            color: Color.black.opacity(0.1),
            radius: 8,
            x: 0,
            y: 4
        )

        static let prominent = ShadowStyle(
            color: Color.black.opacity(0.15),
            radius: 16,
            x: 0,
            y: 8
        )

        struct ShadowStyle {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
    }

    // MARK: - Animation
    enum Animation {
        // Spring animations for organic feel
        static let spring = SwiftUI.Animation.spring(
            response: 0.4,
            dampingFraction: 0.7,
            blendDuration: 0
        )

        static let springBouncy = SwiftUI.Animation.spring(
            response: 0.5,
            dampingFraction: 0.6,
            blendDuration: 0
        )

        // Standard easing
        static let easeOut = SwiftUI.Animation.easeOut(duration: 0.3)
        static let easeIn = SwiftUI.Animation.easeIn(duration: 0.2)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.25)

        // Quick interactions
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
    }

    // MARK: - Icon Sizes
    enum IconSize {
        static let small: CGFloat = 16
        static let medium: CGFloat = 20
        static let large: CGFloat = 24
        static let xlarge: CGFloat = 32
        static let xxlarge: CGFloat = 48
    }

    // MARK: - Avatar Sizes
    enum AvatarSize {
        static let small: CGFloat = 32
        static let medium: CGFloat = 48
        static let large: CGFloat = 64
        static let xlarge: CGFloat = 80
        static let hero: CGFloat = 120
    }
}

// MARK: - View Extensions for Easy Access

extension View {
    // Apply shadow styles
    func shadow(_ style: DesignSystem.Shadow.ShadowStyle) -> some View {
        self.shadow(
            color: style.color,
            radius: style.radius,
            x: style.x,
            y: style.y
        )
    }

    // Card style
    func cardStyle(
        padding: CGFloat = DesignSystem.Spacing.cardPadding,
        cornerRadius: CGFloat = DesignSystem.CornerRadius.large
    ) -> some View {
        self
            .padding(padding)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(cornerRadius)
            .shadow(DesignSystem.Shadow.subtle)
    }

    // Section spacing
    func sectionSpacing() -> some View {
        self.padding(.vertical, DesignSystem.Spacing.sectionSpacing)
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
