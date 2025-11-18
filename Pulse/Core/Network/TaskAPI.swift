import Foundation

/// API for tasks table operations
class TaskAPI {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func createTask(task: TaskItem) async throws -> UUID {
        let dto = TaskDTO(
            groupID: task.groupID,
            createdBy: task.createdByUserID,
            assignedTo: task.assignedToUserID,
            title: task.title,
            completed: task.completed,
            dueDate: task.dueDate
        )

        return try await client.insert(into: "tasks", value: dto)
    }

    func updateTask(task: TaskItem) async throws {
        guard let serverID = task.serverID else {
            throw TaskAPIError.noServerID
        }

        let dto = TaskDTO(
            groupID: task.groupID,
            createdBy: task.createdByUserID,
            assignedTo: task.assignedToUserID,
            title: task.title,
            completed: task.completed,
            dueDate: task.dueDate
        )

        try await client.update(table: "tasks", id: serverID, value: dto)
    }

    func fetchGroupTasks(groupID: UUID) async throws -> [TaskItem] {
        // TODO: Implement
        return []
    }

    func deleteTask(id: UUID) async throws {
        try await client.delete(from: "tasks", id: id)
    }
}

enum TaskAPIError: LocalizedError {
    case noServerID

    var errorDescription: String? {
        switch self {
        case .noServerID:
            return "Task has no server ID"
        }
    }
}
