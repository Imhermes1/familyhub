import SwiftUI

// MARK: - Floating Action Button (FAB)
// Main action button with radial menu

struct FloatingActionButton: View {
    let onCheckIn: () -> Void
    let onNote: () -> Void
    let onTask: () -> Void
    var onVoice: (() -> Void)? = nil  // Phase 2
    var onPhoto: (() -> Void)? = nil  // Phase 3

    @State private var isExpanded = false
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency

    var body: some View {
        ZStack {
            // Background overlay when expanded
            if isExpanded {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(DesignSystem.Animation.springBouncy) {
                            isExpanded = false
                        }
                    }
            }

            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.md) {
                // Action menu items (shown when expanded)
                if isExpanded {
                    actionMenuItems
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                }

                // Main FAB button
                mainButton
            }
        }
    }

    // MARK: - Main Button

    private var mainButton: some View {
        Button {
            HapticManager.shared.impact(.medium)
            withAnimation(DesignSystem.Animation.springBouncy) {
                isExpanded.toggle()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primary)
                    .frame(width: 64, height: 64)

                Image(systemName: isExpanded ? "xmark" : "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
        }
        .shadow(
            color: DesignSystem.Colors.primary.opacity(0.3),
            radius: 12,
            x: 0,
            y: 6
        )
    }

    // MARK: - Action Menu Items

    @ViewBuilder
    private var actionMenuItems: some View {
        VStack(alignment: .trailing, spacing: DesignSystem.Spacing.sm) {
            // Check-in action
            FABMenuItem(
                icon: "location.fill",
                label: "Check In",
                color: DesignSystem.Colors.success
            ) {
                handleAction(onCheckIn)
            }

            // Note action
            FABMenuItem(
                icon: "note.text",
                label: "Quick Note",
                color: DesignSystem.Colors.secondary
            ) {
                handleAction(onNote)
            }

            // Task action
            FABMenuItem(
                icon: "checkmark.circle.fill",
                label: "Add Task",
                color: DesignSystem.Colors.info
            ) {
                handleAction(onTask)
            }

            // Voice action (Phase 2)
            if let onVoice = onVoice {
                FABMenuItem(
                    icon: "mic.fill",
                    label: "Voice Message",
                    color: DesignSystem.Colors.warning
                ) {
                    handleAction(onVoice)
                }
            }

            // Photo action (Phase 3)
            if let onPhoto = onPhoto {
                FABMenuItem(
                    icon: "camera.fill",
                    label: "Share Photo",
                    color: DesignSystem.Colors.accent
                ) {
                    handleAction(onPhoto)
                }
            }
        }
    }

    // MARK: - Helpers

    private func handleAction(_ action: @escaping () -> Void) {
        HapticManager.shared.impact(.light)
        withAnimation(DesignSystem.Animation.spring) {
            isExpanded = false
        }
        // Delay action slightly to allow close animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            action()
        }
    }
}

// MARK: - FAB Menu Item

struct FABMenuItem: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                // Label
                Text(label)
                    .font(DesignSystem.Typography.callout(.semibold))
                    .foregroundColor(DesignSystem.Colors.label)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(DesignSystem.Colors.cardBackground)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .shadow(DesignSystem.Shadow.subtle)

                // Icon button
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: DesignSystem.IconSize.medium, weight: .semibold))
                        .foregroundColor(.white)
                }
                .shadow(
                    color: color.opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        // Background content
        Color.gray.opacity(0.1).ignoresSafeArea()

        VStack {
            Spacer()
            HStack {
                Spacer()

                FloatingActionButton(
                    onCheckIn: { print("Check In") },
                    onNote: { print("Note") },
                    onTask: { print("Task") },
                    onVoice: { print("Voice") },
                    onPhoto: { print("Photo") }
                )
                .padding()
            }
        }
    }
}
