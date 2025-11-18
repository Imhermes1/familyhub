import Foundation

/// Manages Supabase Realtime subscriptions
class RealtimeManager {
    private let supabaseClient: SupabaseClient
    private let groupID: UUID
    private var statusChannel: RealtimeChannel?
    private var taskChannel: RealtimeChannel?

    private let onStatusUpdate: () async -> Void
    private let onTaskUpdate: () async -> Void

    init(
        supabaseClient: SupabaseClient,
        groupID: UUID,
        onStatusUpdate: @escaping () async -> Void,
        onTaskUpdate: @escaping () async -> Void
    ) {
        self.supabaseClient = supabaseClient
        self.groupID = groupID
        self.onStatusUpdate = onStatusUpdate
        self.onTaskUpdate = onTaskUpdate
    }

    func connect() async {
        // Subscribe to status_events changes
        statusChannel = supabaseClient.subscribeToChannel("status_events:\(groupID)")
            .on("INSERT") {
                Task {
                    await self.onStatusUpdate()
                }
            }
            .on("UPDATE") {
                Task {
                    await self.onStatusUpdate()
                }
            }

        await statusChannel?.subscribe()

        // Subscribe to tasks changes
        taskChannel = supabaseClient.subscribeToChannel("tasks:\(groupID)")
            .on("INSERT") {
                Task {
                    await self.onTaskUpdate()
                }
            }
            .on("UPDATE") {
                Task {
                    await self.onTaskUpdate()
                }
            }

        await taskChannel?.subscribe()

        print("Realtime subscriptions connected for group: \(groupID)")
    }

    func disconnect() async {
        await statusChannel?.unsubscribe()
        await taskChannel?.unsubscribe()
        print("Realtime subscriptions disconnected")
    }
}
