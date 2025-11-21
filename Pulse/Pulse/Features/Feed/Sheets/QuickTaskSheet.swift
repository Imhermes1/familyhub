import SwiftUI

// MARK: - Quick Task Sheet
// Minimal, beautiful sheet for creating tasks

struct QuickTaskSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: PulseDataManager

    @State private var title: String = ""
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    @State private var isLoading = false
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Content
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Task title input
                        taskTitleInput
                            .padding(.top, DesignSystem.Spacing.md)

                        // Due date toggle
                        dueDateSection

                        // Submit button
                        ActionButton(
                            "Add Task",
                            icon: "checkmark.circle.fill",
                            isLoading: isLoading,
                            isDisabled: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ) {
                            addTask()
                        }
                        .padding(.top, DesignSystem.Spacing.md)
                    }
                    .padding(DesignSystem.Spacing.screenPadding)
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Auto-focus on input
                isFocused = true
            }
        }
    }

    // MARK: - Task Title Input

    private var taskTitleInput: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("What needs to be done?")
                .font(DesignSystem.Typography.headline())
                .foregroundColor(DesignSystem.Colors.label)

            TextField("Enter task title", text: $title)
                .font(DesignSystem.Typography.body())
                .padding()
                .background(DesignSystem.Colors.secondaryBackground)
                .cornerRadius(DesignSystem.CornerRadius.medium)
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit {
                    if !title.isEmpty {
                        addTask()
                    }
                }
        }
    }

    // MARK: - Due Date Section

    private var dueDateSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Toggle for due date
            Card {
                Toggle(isOn: $hasDueDate.animation(DesignSystem.Animation.spring)) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "calendar")
                            .font(.system(size: DesignSystem.IconSize.medium))
                            .foregroundColor(hasDueDate ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryLabel)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Set Due Date")
                                .font(DesignSystem.Typography.body(.semibold))
                                .foregroundColor(DesignSystem.Colors.label)

                            if !hasDueDate {
                                Text("Task will have no deadline")
                                    .font(DesignSystem.Typography.caption1())
                                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
                            }
                        }
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.primary))
            }

            // Date picker (shown when enabled)
            if hasDueDate {
                Card {
                    DatePicker(
                        "Due Date",
                        selection: $dueDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
    }

    // MARK: - Actions

    private func addTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        Task {
            isLoading = true
            HapticManager.shared.impact(.medium)

            do {
                // Create task
                try await dataManager.addTask(
                    title: trimmedTitle,
                    dueDate: hasDueDate ? dueDate : nil
                )

                // Track analytics
                PostHogManager.shared.track(.taskCreated, properties: [
                    "has_due_date": hasDueDate,
                    "title_length": trimmedTitle.count
                ])

                // Success haptic
                HapticManager.shared.notification(.success)

                // Close sheet
                dismiss()
            } catch {
                // Error haptic
                HapticManager.shared.notification(.error)
                print("Task creation failed: \(error)")
            }

            isLoading = false
        }
    }
}

// MARK: - Preview
#Preview {
    QuickTaskSheet()
        .environmentObject(PulseDataManager.shared)
}
