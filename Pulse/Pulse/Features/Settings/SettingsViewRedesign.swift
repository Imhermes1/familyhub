import SwiftUI

// MARK: - Settings View (Redesigned)
// Beautiful, minimal settings with card-based layout

struct SettingsViewRedesign: View {
    @EnvironmentObject var dataManager: PulseDataManager
    @Environment(\.dismiss) var dismiss
    @State private var profile: UserProfile?
    @State private var showingProfileEdit = false
    @State private var showingGroupManagement = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Profile card
                    profileCard

                    // Current status card
                    currentStatusCard

                    // Automation settings
                    automationSection

                    // Group settings
                    groupSection

                    // App settings
                    appSection

                    // Danger zone
                    dangerZoneSection
                }
                .padding(DesignSystem.Spacing.screenPadding)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            profile = dataManager.currentUser
            PostHogManager.shared.screen("settings_redesign")
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        Card.prominent {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Avatar
                AvatarView(
                    emoji: profile?.emoji ?? "👤",
                    size: .xlarge,
                    showStatus: false
                )

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile?.displayName ?? "User")
                        .font(DesignSystem.Typography.title3(.bold))
                        .foregroundColor(DesignSystem.Colors.label)

                    if let phoneNumber = profile?.phoneNumber {
                        Text(phoneNumber)
                            .font(DesignSystem.Typography.callout())
                            .foregroundColor(DesignSystem.Colors.secondaryLabel)
                    }
                }

                Spacer()

                // Edit button
                Button {
                    showingProfileEdit = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: DesignSystem.IconSize.xlarge))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
    }

    // MARK: - Current Status Card

    private var currentStatusCard: some View {
        Card {
            VStack(spacing: DesignSystem.Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Mode")
                            .font(DesignSystem.Typography.headline())

                        Text(currentModeText)
                            .font(DesignSystem.Typography.caption1())
                            .foregroundColor(DesignSystem.Colors.secondaryLabel)
                    }

                    Spacer()

                    StatusIndicator(
                        status: currentModeStatus,
                        size: .large,
                        animated: true
                    )
                }

                if profile?.manualOnlyMode == true {
                    Text("All automation is disabled. You'll need to check in manually.")
                        .font(DesignSystem.Typography.caption1())
                        .foregroundColor(DesignSystem.Colors.warning)
                        .padding(.top, 4)
                }
            }
        }
    }

    private var currentModeText: String {
        if profile?.manualOnlyMode == true {
            return "Manual Only"
        } else if profile?.isAutomationEnabled() == true {
            return "Automated"
        } else {
            return "Inactive"
        }
    }

    private var currentModeStatus: UserStatus {
        if profile?.manualOnlyMode == true {
            return .away
        } else if profile?.isAutomationEnabled() == true {
            return .online
        } else {
            return .offline
        }
    }

    // MARK: - Automation Section

    private var automationSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Automation")
                .font(DesignSystem.Typography.title3(.semibold))
                .foregroundColor(DesignSystem.Colors.label)

            VStack(spacing: DesignSystem.Spacing.xs) {
                // Manual Only Mode
                ToggleCard(
                    icon: "hand.raised.fill",
                    title: "Manual Only Mode",
                    description: "Disable all automation features",
                    isOn: manualOnlyBinding,
                    color: DesignSystem.Colors.warning
                )

                // Car Bluetooth
                ToggleCard(
                    icon: "car.fill",
                    title: "Car Bluetooth",
                    description: "Auto check-in when connected to car",
                    isOn: bluetoothBinding,
                    color: DesignSystem.Colors.info,
                    isDisabled: profile?.manualOnlyMode ?? false
                )

                // Geofences
                ToggleCard(
                    icon: "location.fill",
                    title: "Geofences",
                    description: "Auto check-in at home and work",
                    isOn: geofenceBinding,
                    color: DesignSystem.Colors.success,
                    isDisabled: profile?.manualOnlyMode ?? false
                )

                // Hourly Pulse
                ToggleCard(
                    icon: "clock.fill",
                    title: "Hourly Pulse",
                    description: "Send periodic status updates",
                    isOn: hourlyPulseBinding,
                    color: DesignSystem.Colors.secondary,
                    isDisabled: profile?.manualOnlyMode ?? false
                )
            }
        }
    }

    // MARK: - Group Section

    private var groupSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Group")
                .font(DesignSystem.Typography.title3(.semibold))
                .foregroundColor(DesignSystem.Colors.label)

            Card {
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Group info row
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dataManager.currentGroup?.name ?? "No Group")
                                .font(DesignSystem.Typography.headline())

                            Text("\(dataManager.currentGroup?.memberCount ?? 0) members")
                                .font(DesignSystem.Typography.caption1())
                                .foregroundColor(DesignSystem.Colors.secondaryLabel)
                        }

                        Spacer()

                        Button {
                            showingGroupManagement = true
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: DesignSystem.IconSize.small, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.secondaryLabel)
                        }
                    }

                    Divider()

                    // Invite code
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Invite Code")
                                .font(DesignSystem.Typography.callout(.medium))
                                .foregroundColor(DesignSystem.Colors.label)

                            Text(dataManager.currentGroup?.inviteCode ?? "——————")
                                .font(DesignSystem.Typography.title3(.bold))
                                .foregroundColor(DesignSystem.Colors.primary)
                                .textSelection(.enabled)
                        }

                        Spacer()

                        Button {
                            copyInviteCode()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: DesignSystem.IconSize.small))
                                Text("Copy")
                                    .font(DesignSystem.Typography.callout(.medium))
                            }
                            .foregroundColor(DesignSystem.Colors.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(DesignSystem.Colors.primaryLight)
                            .cornerRadius(DesignSystem.CornerRadius.small)
                        }
                    }
                }
            }
        }
    }

    // MARK: - App Section

    private var appSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("App")
                .font(DesignSystem.Typography.title3(.semibold))
                .foregroundColor(DesignSystem.Colors.label)

            VStack(spacing: DesignSystem.Spacing.xs) {
                SettingsRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    value: "Enabled",
                    color: DesignSystem.Colors.primary
                ) {
                    // TODO: Navigate to notifications settings
                }

                ToggleCard(
                    icon: "chart.bar.fill",
                    title: "Share Analytics",
                    description: "Help us improve the app",
                    isOn: .constant(true),
                    color: DesignSystem.Colors.info
                )

                SettingsRow(
                    icon: "questionmark.circle.fill",
                    title: "Help & Support",
                    color: DesignSystem.Colors.info
                ) {
                    // TODO: Navigate to help
                }

                SettingsRow(
                    icon: "doc.text.fill",
                    title: "Privacy Policy",
                    color: DesignSystem.Colors.secondary
                ) {
                    // TODO: Open privacy policy
                }
            }
        }
    }

    // MARK: - Danger Zone

    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Danger Zone")
                .font(DesignSystem.Typography.title3(.semibold))
                .foregroundColor(DesignSystem.Colors.error)

            VStack(spacing: DesignSystem.Spacing.xs) {
                SettingsRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: "Leave Group",
                    color: DesignSystem.Colors.warning
                ) {
                    // TODO: Leave group confirmation
                }

                SettingsRow(
                    icon: "trash.fill",
                    title: "Delete Account",
                    color: DesignSystem.Colors.error
                ) {
                    // TODO: Delete account confirmation
                }
            }
        }
    }

    // MARK: - Bindings

    private var bluetoothBinding: Binding<Bool> {
        Binding(
            get: { profile?.bluetoothAutomation ?? false },
            set: { newValue in
                profile?.bluetoothAutomation = newValue
                saveSettings()
                PostHogManager.shared.track(.settingsChanged, properties: [
                    "setting": "bluetooth_automation",
                    "value": newValue
                ])
            }
        )
    }

    private var geofenceBinding: Binding<Bool> {
        Binding(
            get: { profile?.geofenceAutomation ?? false },
            set: { newValue in
                profile?.geofenceAutomation = newValue
                saveSettings()
                PostHogManager.shared.track(.settingsChanged, properties: [
                    "setting": "geofence_automation",
                    "value": newValue
                ])
            }
        )
    }

    private var hourlyPulseBinding: Binding<Bool> {
        Binding(
            get: { profile?.hourlyPulse ?? false },
            set: { newValue in
                profile?.hourlyPulse = newValue
                saveSettings()
                PostHogManager.shared.track(.settingsChanged, properties: [
                    "setting": "hourly_pulse",
                    "value": newValue
                ])
            }
        )
    }

    private var manualOnlyBinding: Binding<Bool> {
        Binding(
            get: { profile?.manualOnlyMode ?? false },
            set: { newValue in
                profile?.manualOnlyMode = newValue
                saveSettings()
                HapticManager.shared.impact(.medium)
                PostHogManager.shared.track(.settingsChanged, properties: [
                    "setting": "manual_only_mode",
                    "value": newValue
                ])
            }
        )
    }

    // MARK: - Actions

    private func saveSettings() {
        // TODO: Save to SwiftData and sync to Supabase
    }

    private func copyInviteCode() {
        if let code = dataManager.currentGroup?.inviteCode {
            UIPasteboard.general.string = code
            HapticManager.shared.notification(.success)
            // TODO: Show toast notification
        }
    }
}

// MARK: - Toggle Card

struct ToggleCard: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool
    let color: Color
    var isDisabled: Bool = false

    var body: some View {
        Card {
            Toggle(isOn: $isOn.animation(DesignSystem.Animation.spring)) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(isDisabled ? DesignSystem.Colors.tertiaryBackground : color.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: icon)
                            .font(.system(size: DesignSystem.IconSize.medium))
                            .foregroundColor(isDisabled ? DesignSystem.Colors.tertiaryLabel : color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(DesignSystem.Typography.body(.semibold))
                            .foregroundColor(DesignSystem.Colors.label)

                        Text(description)
                            .font(DesignSystem.Typography.caption1())
                            .foregroundColor(DesignSystem.Colors.secondaryLabel)
                    }
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: color))
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.5 : 1.0)
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let title: String
    var value: String? = nil
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Card {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: icon)
                            .font(.system(size: DesignSystem.IconSize.medium))
                            .foregroundColor(color)
                    }

                    Text(title)
                        .font(DesignSystem.Typography.body(.semibold))
                        .foregroundColor(DesignSystem.Colors.label)

                    Spacer()

                    if let value = value {
                        Text(value)
                            .font(DesignSystem.Typography.callout())
                            .foregroundColor(DesignSystem.Colors.secondaryLabel)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: DesignSystem.IconSize.small, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    SettingsViewRedesign()
        .environmentObject(PulseDataManager.shared)
}
