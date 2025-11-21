import SwiftUI

// MARK: - Quick Note Sheet
// Minimal, beautiful sheet for creating notes

struct QuickNoteSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: PulseDataManager

    @State private var content: String = ""
    @State private var isLoading = false
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Content
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Note input
                    noteInput
                        .padding(.top, DesignSystem.Spacing.md)

                    Spacer()

                    // Submit button
                    ActionButton(
                        "Share Note",
                        icon: "paperplane.fill",
                        isLoading: isLoading,
                        isDisabled: content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ) {
                        addNote()
                    }
                }
                .padding(DesignSystem.Spacing.screenPadding)
            }
            .navigationTitle("Quick Note")
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

    // MARK: - Note Input

    private var noteInput: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("What's on your mind?")
                .font(DesignSystem.Typography.headline())
                .foregroundColor(DesignSystem.Colors.label)

            ZStack(alignment: .topLeading) {
                // Placeholder
                if content.isEmpty {
                    Text("Share a quick update with your group...")
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }

                // Text editor
                TextEditor(text: $content)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(DesignSystem.Colors.label)
                    .frame(minHeight: 150)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($isFocused)
            }
            .padding(4)
            .background(DesignSystem.Colors.secondaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.medium)

            // Character count
            HStack {
                Spacer()
                Text("\(content.count) characters")
                    .font(DesignSystem.Typography.caption2())
                    .foregroundColor(DesignSystem.Colors.tertiaryLabel)
            }
        }
    }

    // MARK: - Actions

    private func addNote() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }

        Task {
            isLoading = true
            HapticManager.shared.impact(.medium)

            do {
                // Create note
                try await dataManager.addNote(content: trimmedContent)

                // Track analytics
                PostHogManager.shared.track(.noteCreated, properties: [
                    "length": trimmedContent.count
                ])

                // Success haptic
                HapticManager.shared.notification(.success)

                // Close sheet
                dismiss()
            } catch {
                // Error haptic
                HapticManager.shared.notification(.error)
                print("Note creation failed: \(error)")
            }

            isLoading = false
        }
    }
}

// MARK: - Preview
#Preview {
    QuickNoteSheet()
        .environmentObject(PulseDataManager.shared)
}
