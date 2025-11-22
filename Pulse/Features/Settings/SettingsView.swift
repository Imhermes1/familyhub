import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataManager: PulseDataManager
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @State private var profile: UserProfile?

    var glassVariant: Glass {
        reduceTransparency ? .identity : .regular
    }

    var body: some View {
        NavigationStack {
            Form {
                // Current mode hero card with Liquid Glass
                Section {
                    CurrentModeCard(
                        automationEnabled: profile?.isAutomationEnabled() ?? false,
                        manualOnlyMode: profile?.manualOnlyMode ?? false,
                        glassVariant: glassVariant
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                // Profile section
                Section("Profile") {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(profile?.displayName ?? "")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Emoji")
                        Spacer()
                        Text(profile?.emoji ?? "👤")
                    }
                }

                // Group section
                Section("Group") {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(dataManager.currentGroup?.name ?? "")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Members")
                        Spacer()
                        Text("\(dataManager.currentGroup?.memberCount ?? 0)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Invite Code")
                        Spacer()
                        Text(dataManager.currentGroup?.inviteCode ?? "")
                            .foregroundStyle(.secondary)
                            .fontWeight(.medium)
                    }
                }

                // Automation section
                Section("Automation") {
                    Toggle("Car Bluetooth", isOn: bluetoothBinding)
                        .disabled(profile?.manualOnlyMode ?? false)

                    Toggle("Geofences", isOn: geofenceBinding)
                        .disabled(profile?.manualOnlyMode ?? false)

                    Toggle("Hourly Pulse", isOn: hourlyPulseBinding)
                        .disabled(profile?.manualOnlyMode ?? false)
                }

                // Privacy section
                Section {
                    Toggle("Manual Only Mode", isOn: manualOnlyBinding)
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("When enabled, all automation is disabled and you must manually check in.")
                        .font(.caption)
                }

                // Analytics
                Section("Analytics") {
                    Toggle("Share Analytics", isOn: .constant(true))
                }
            }
            .navigationTitle("Settings")
        }
        .onAppear {
            profile = dataManager.currentUser
            PostHogManager.shared.screen("settings")
        }
    }

    // MARK: - Bindings

    private var bluetoothBinding: Binding<Bool> {
        Binding(
            get: { profile?.bluetoothAutomation ?? false },
            set: { newValue in
                profile?.bluetoothAutomation = newValue
                saveSettings()
            }
        )
    }

    private var geofenceBinding: Binding<Bool> {
        Binding(
            get: { profile?.geofenceAutomation ?? false },
            set: { newValue in
                profile?.geofenceAutomation = newValue
                saveSettings()
            }
        )
    }

    private var hourlyPulseBinding: Binding<Bool> {
        Binding(
            get: { profile?.hourlyPulse ?? false },
            set: { newValue in
                profile?.hourlyPulse = newValue
                saveSettings()
            }
        )
    }

    private var manualOnlyBinding: Binding<Bool> {
        Binding(
            get: { profile?.manualOnlyMode ?? false },
            set: { newValue in
                profile?.manualOnlyMode = newValue
                saveSettings()

                PostHogManager.shared.track("settings_changed", properties: [
                    "setting_key": "manual_only_mode",
                    "new_value": newValue
                ])
            }
        )
    }

    private func saveSettings() {
        // TODO: Save to SwiftData and sync to Supabase
    }
}

#Preview {
    SettingsView()
        .environmentObject(PulseDataManager.shared)
}
