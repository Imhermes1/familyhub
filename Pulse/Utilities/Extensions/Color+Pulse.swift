import SwiftUI

extension Color {
    // MARK: - Semantic Colors for Pulse

    /// Primary accent color for the app
    static let pulseAccent = Color.blue

    /// Color for arrived/safe status
    static let statusArrived = Color.green

    /// Color for leaving status
    static let statusLeaving = Color.orange

    /// Color for on the way status
    static let statusOnTheWay = Color.blue

    /// Color for pulse/active status
    static let statusPulse = Color.purple

    /// Color for automation enabled indicator
    static let automationActive = Color.green

    /// Color for manual mode
    static let manualMode = Color.orange

    // MARK: - Status Colors by Type

    static func statusColor(for statusType: String) -> Color {
        switch statusType {
        case "arrived":
            return .statusArrived
        case "leaving":
            return .statusLeaving
        case "on_the_way":
            return .statusOnTheWay
        case "pulse":
            return .statusPulse
        default:
            return .secondary
        }
    }

    // MARK: - Accessibility

    /// Returns a high contrast version of the color when needed
    func highContrast(enabled: Bool) -> Color {
        enabled ? self : self
    }
}

// MARK: - Gradient Helpers

extension LinearGradient {
    /// Subtle gradient for glass backgrounds
    static var glassGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.1),
                Color.white.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Status gradient for cards
    static func statusGradient(color: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                color.opacity(0.2),
                color.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
