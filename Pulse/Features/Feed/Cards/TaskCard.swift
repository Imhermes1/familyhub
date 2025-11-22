import SwiftUI

// MARK: - Task Card
// Beautiful card for task items in the feed

struct TaskCard: View {
    let task: TaskItem
    let userName: String?
    let userEmoji: String?
    let onToggle: (TaskItem) -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                // Header with avatar and user info
                HStack(spacing: DesignSystem.Spacing.sm) {
                    AvatarView(
                        emoji: userEmoji ?? "👤",
                        size: .medium,
                        showStatus: false
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(userName ?? "Unknown")
                            .font(DesignSystem.Typography.headline())

                        HStack(spacing: 4) {
                            Text("Task")
                                .font(DesignSystem.Typography.caption1(.medium))
                                .foregroundColor(DesignSystem.Colors.primary)

                            if let dueDate = task.dueDate {
                                Text("•")
                                    .font(DesignSystem.Typography.caption2())
                                    .foregroundColor(DesignSystem.Colors.tertiaryLabel)

                                Text(dueDateText(dueDate))
                                    .font(DesignSystem.Typography.caption1())
                                    .foregroundColor(dueDateColor(dueDate))
                            }
                        }
                    }

                    Spacer()

                    // Task status icon
                    Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: DesignSystem.IconSize.large))
                        .foregroundColor(task.completed ? DesignSystem.Colors.success : DesignSystem.Colors.secondaryLabel)
                }

                // Task title with checkbox
                Button {
                    HapticManager.shared.impact(.medium)
                    onToggle(task)
                } label: {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        // Checkbox
                        Image(systemName: task.completed ? "checkmark.square.fill" : "square")
                            .font(.system(size: DesignSystem.IconSize.medium))
                            .foregroundColor(task.completed ? DesignSystem.Colors.success : DesignSystem.Colors.secondaryLabel)

                        // Task title
                        Text(task.title)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(task.completed ? DesignSystem.Colors.secondaryLabel : DesignSystem.Colors.label)
                            .strikethrough(task.completed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 4)

                // Completion info if completed
                if task.completed, let completedAt = task.completedAt {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: DesignSystem.IconSize.small))
                            .foregroundColor(DesignSystem.Colors.success)

                        Text("Completed \(timeAgo(completedAt))")
                            .font(DesignSystem.Typography.caption1())
                            .foregroundColor(DesignSystem.Colors.secondaryLabel)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private func dueDateText(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return "Due today"
        } else if calendar.isDateInTomorrow(date) {
            return "Due tomorrow"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return "Due \(formatter.string(from: date))"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return "Due \(formatter.string(from: date))"
        }
    }

    private func dueDateColor(_ date: Date) -> Color {
        let now = Date()
        if date < now {
            return DesignSystem.Colors.error
        } else if Calendar.current.isDateInToday(date) {
            return DesignSystem.Colors.warning
        } else {
            return DesignSystem.Colors.secondaryLabel
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        TaskCard(
            task: TaskItem(
                groupID: UUID(),
                createdByUserID: UUID(),
                title: "Buy groceries for dinner tonight",
                completed: false,
                dueDate: Calendar.current.date(byAdding: .day, value: 0, to: Date())
            ),
            userName: "Mom",
            userEmoji: "👩",
            onToggle: { _ in }
        )

        TaskCard(
            task: TaskItem(
                groupID: UUID(),
                createdByUserID: UUID(),
                title: "Pick up kids from school",
                completed: true,
                completedAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()),
                dueDate: Calendar.current.date(byAdding: .hour, value: -2, to: Date())
            ),
            userName: "Dad",
            userEmoji: "👨",
            onToggle: { _ in }
        )

        TaskCard(
            task: TaskItem(
                groupID: UUID(),
                createdByUserID: UUID(),
                title: "Schedule dentist appointment",
                completed: false,
                dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())
            ),
            userName: "Sister",
            userEmoji: "👧",
            onToggle: { _ in }
        )
    }
    .padding()
}
