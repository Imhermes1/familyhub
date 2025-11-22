import SwiftUI

// MARK: - Quick Check-In Sheet
// Minimal, beautiful sheet for manual check-ins

struct QuickCheckInSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: PulseDataManager

    @State private var selectedType: StatusType = .arrived
    @State private var locationName: String = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Content
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Status type selection
                        statusTypeSelection
                            .padding(.top, DesignSystem.Spacing.md)

                        // Location input
                        locationInput

                        // Submit button
                        ActionButton(
                            "Check In",
                            icon: "location.fill",
                            isLoading: isLoading
                        ) {
                            checkIn()
                        }
                        .padding(.top, DesignSystem.Spacing.md)
                    }
                    .padding(DesignSystem.Spacing.screenPadding)
                }
            }
            .navigationTitle("Check In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Status Type Selection

    private var statusTypeSelection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("What's happening?")
                .font(DesignSystem.Typography.headline())
                .foregroundColor(DesignSystem.Colors.label)

            VStack(spacing: DesignSystem.Spacing.xs) {
                StatusTypeButton(
                    type: .arrived,
                    isSelected: selectedType == .arrived
                ) {
                    withAnimation(DesignSystem.Animation.spring) {
                        selectedType = .arrived
                    }
                }

                StatusTypeButton(
                    type: .leaving,
                    isSelected: selectedType == .leaving
                ) {
                    withAnimation(DesignSystem.Animation.spring) {
                        selectedType = .leaving
                    }
                }

                StatusTypeButton(
                    type: .onTheWay,
                    isSelected: selectedType == .onTheWay
                ) {
                    withAnimation(DesignSystem.Animation.spring) {
                        selectedType = .onTheWay
                    }
                }
            }
        }
    }

    // MARK: - Location Input

    private var locationInput: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Where? (optional)")
                .font(DesignSystem.Typography.headline())
                .foregroundColor(DesignSystem.Colors.label)

            TextField("Enter location", text: $locationName)
                .font(DesignSystem.Typography.body())
                .padding()
                .background(DesignSystem.Colors.secondaryBackground)
                .cornerRadius(DesignSystem.CornerRadius.medium)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
        }
    }

    // MARK: - Actions

    private func checkIn() {
        Task {
            isLoading = true
            HapticManager.shared.impact(.medium)

            do {
                // Create check-in
                try await dataManager.checkIn(
                    type: selectedType,
                    locationName: locationName.isEmpty ? nil : locationName
                )

                // Track analytics
                PostHogManager.shared.track("check_in_performed", properties: [
                    "type": selectedType.rawValue,
                    "trigger": "manual",
                    "has_location": !locationName.isEmpty
                ])

                // Success haptic
                HapticManager.shared.notification(.success)

                // Close sheet
                dismiss()
            } catch {
                // Error haptic
                HapticManager.shared.notification(.error)
                print("Check-in failed: \(error)")
            }

            isLoading = false
        }
    }
}

// MARK: - Status Type Button

struct StatusTypeButton: View {
    let type: StatusType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? type.color : DesignSystem.Colors.tertiaryBackground)
                        .frame(width: 44, height: 44)

                    Image(systemName: type.icon)
                        .font(.system(size: DesignSystem.IconSize.medium))
                        .foregroundColor(isSelected ? .white : DesignSystem.Colors.secondaryLabel)
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayText)
                        .font(DesignSystem.Typography.body(.semibold))
                        .foregroundColor(DesignSystem.Colors.label)

                    Text(type.description)
                        .font(DesignSystem.Typography.caption1())
                        .foregroundColor(DesignSystem.Colors.secondaryLabel)
                }

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: DesignSystem.IconSize.large))
                        .foregroundColor(type.color)
                }
            }
            .padding(DesignSystem.Spacing.sm)
            .background(isSelected ? type.color.opacity(0.1) : DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(isSelected ? type.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status Type Extensions

extension StatusType {
    var color: Color {
        switch self {
        case .arrived:
            return DesignSystem.Colors.success
        case .leaving:
            return DesignSystem.Colors.warning
        case .onTheWay:
            return DesignSystem.Colors.info
        case .pulse:
            return DesignSystem.Colors.primary
        }
    }

    var description: String {
        switch self {
        case .arrived:
            return "I've arrived at a location"
        case .leaving:
            return "I'm leaving a location"
        case .onTheWay:
            return "I'm heading somewhere"
        case .pulse:
            return "Quick status update"
        }
    }
}

// MARK: - Preview
#Preview {
    QuickCheckInSheet()
        .environmentObject(PulseDataManager.shared)
}
