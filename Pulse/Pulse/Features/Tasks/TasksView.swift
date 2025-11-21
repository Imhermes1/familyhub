import SwiftUI

struct TasksView: View {
    @EnvironmentObject var dataManager: PulseDataManager
    @State private var showAddTask = false
    @State private var selectedSegment = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented control for Tasks/Notes
                Picker("View", selection: $selectedSegment) {
                    Text("Tasks").tag(0)
                    Text("Notes").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedSegment == 0 {
                    TaskListView(
                        tasks: dataManager.tasks,
                        onToggle: { task in
                            Task {
                                try? await dataManager.toggleTask(task)
                            }
                        }
                    )
                } else {
                    NotesView()
                }
            }
            .navigationTitle("Tasks & Notes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.glass)
                }
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskSheet()
            }
        }
        .onAppear {
            PostHogManager.shared.screen("tasks")
        }
    }
}

struct TaskListView: View {
    let tasks: [TaskItem]
    let onToggle: (TaskItem) -> Void

    var body: some View {
        // Standard List - NO GLASS
        List {
            ForEach(tasks) { task in
                TaskRow(task: task, onToggle: onToggle)
            }
        }
        .listStyle(.plain)
    }
}

struct TaskRow: View {
    let task: TaskItem
    let onToggle: (TaskItem) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onToggle(task)
            } label: {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.completed ? .green : .secondary)
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(.body)
                .strikethrough(task.completed)
                .foregroundStyle(task.completed ? .secondary : .primary)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct AddTaskSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: PulseDataManager
    @State private var title = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Task title", text: $title)
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTask()
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func addTask() {
        Task {
            try? await dataManager.addTask(title: title)
            dismiss()
        }
    }
}

#Preview {
    TasksView()
        .environmentObject(PulseDataManager.shared)
}
