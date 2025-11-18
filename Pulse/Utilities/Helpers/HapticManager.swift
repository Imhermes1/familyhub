import UIKit
import SwiftUI

/// Manages haptic feedback throughout the app
class HapticManager {
    static let shared = HapticManager()

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    private init() {
        // Prepare generators
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notification.prepare()
        selection.prepare()
    }

    // MARK: - Impact Feedback

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        switch style {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.impactOccurred()
        case .soft, .rigid:
            impactMedium.impactOccurred()
        @unknown default:
            impactMedium.impactOccurred()
        }
    }

    // MARK: - Notification Feedback

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notification.notificationOccurred(type)
    }

    func success() {
        notification.notificationOccurred(.success)
    }

    func warning() {
        notification.notificationOccurred(.warning)
    }

    func error() {
        notification.notificationOccurred(.error)
    }

    // MARK: - Selection Feedback

    func selection() {
        selection.selectionChanged()
    }

    // MARK: - Pulse-Specific Feedback

    /// Haptic for check-in action
    func checkIn() {
        impactMedium.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.notification.notificationOccurred(.success)
        }
    }

    /// Haptic for task completion
    func taskCompleted() {
        selection.selectionChanged()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.impactLight.impactOccurred()
        }
    }

    /// Haptic for automation trigger
    func automationTriggered() {
        impactLight.impactOccurred()
    }

    /// Haptic for error
    func errorOccurred() {
        notification.notificationOccurred(.error)
    }
}

// MARK: - SwiftUI View Extension

extension View {
    /// Adds haptic feedback on tap
    func hapticFeedback(
        _ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium,
        onTap: Bool = true
    ) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                if onTap {
                    HapticManager.shared.impact(style)
                }
            }
        )
    }

    /// Adds success haptic on tap
    func successHaptic(onTap: Bool = true) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                if onTap {
                    HapticManager.shared.success()
                }
            }
        )
    }
}
