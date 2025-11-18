import Foundation
import SwiftData
import Combine

@MainActor
class PulseDataManager: ObservableObject {
    static let shared = PulseDataManager()

    // Dependencies
    private(set) var supabaseClient: SupabaseClient!
    private(set) var modelContext: ModelContext!
    private(set) var appGroupStore: AppGroupStore!
    private(set) var realtimeManager: RealtimeManager!

    // Published state
    @Published var currentUser: UserProfile?
    @Published var currentGroup: Group?
    @Published var statuses: [PulseStatus] = []
    @Published var tasks: [TaskItem] = []
    @Published var notes: [Note] = []
    @Published var isLoading = false
    @Published var error: Error?

    private init() {}

    func initialize(modelContext: ModelContext) async {
        self.modelContext = modelContext
        self.supabaseClient = SupabaseClient()
        self.appGroupStore = AppGroupStore()

        // Load current user and group from SwiftData
        await loadLocalData()

        // Initialize realtime subscriptions if authenticated
        if let currentUser = currentUser, let currentGroup = currentGroup {
            self.realtimeManager = RealtimeManager(
                supabaseClient: supabaseClient,
                groupID: currentGroup.id,
                onStatusUpdate: { [weak self] in
                    await self?.syncStatusesFromSupabase()
                },
                onTaskUpdate: { [weak self] in
                    await self?.syncTasksFromSupabase()
                }
            )
            await realtimeManager.connect()
        }
    }

    // MARK: - Authentication

    func isUserAuthenticated() async -> Bool {
        do {
            return try await supabaseClient.isAuthenticated()
        } catch {
            return false
        }
    }

    func hasCompletedOnboarding() async -> Bool {
        return currentUser != nil && currentGroup != nil
    }

    func signIn(email: String) async throws {
        try await supabaseClient.signInWithMagicLink(email: email)
    }

    func signOut() async throws {
        try await supabaseClient.signOut()
        currentUser = nil
        currentGroup = nil
        statuses = []
        tasks = []
        notes = []
    }

    // MARK: - Profile Setup

    func createUserProfile(displayName: String, emoji: String) async throws {
        let authUserID = try await supabaseClient.getCurrentUserID()

        let profile = UserProfile(
            authUserID: authUserID,
            displayName: displayName,
            emoji: emoji
        )

        modelContext.insert(profile)
        try modelContext.save()

        // Sync to Supabase
        try await UserAPI(client: supabaseClient).createUser(profile: profile)

        currentUser = profile
    }

    func createGroup(name: String) async throws {
        guard let currentUser = currentUser else {
            throw PulseError.userNotAuthenticated
        }

        let inviteCode = generateInviteCode()
        let group = Group(
            name: name,
            inviteCode: inviteCode,
            createdByUserID: currentUser.id,
            memberIDs: [currentUser.id],
            memberCount: 1
        )

        modelContext.insert(group)
        try modelContext.save()

        // Sync to Supabase
        try await GroupAPI(client: supabaseClient).createGroup(group: group, creatorID: currentUser.id)

        currentGroup = group
    }

    func joinGroup(inviteCode: String) async throws {
        guard let currentUser = currentUser else {
            throw PulseError.userNotAuthenticated
        }

        // Fetch group from Supabase
        let group = try await GroupAPI(client: supabaseClient).joinGroup(inviteCode: inviteCode, userID: currentUser.id)

        modelContext.insert(group)
        try modelContext.save()

        currentGroup = group
    }

    // MARK: - Check-in

    func checkIn(type: StatusType, trigger: TriggerType = .manual, locationName: String? = nil) async throws {
        guard let currentUser = currentUser, let currentGroup = currentGroup else {
            throw PulseError.userNotAuthenticated
        }

        // Prevent auto updates if manual-only mode is enabled
        if currentUser.manualOnlyMode && trigger != .manual {
            return
        }

        // Create status locally (optimistic update)
        let status = PulseStatus(
            userID: currentUser.id,
            groupID: currentGroup.id,
            statusType: type,
            triggerType: trigger,
            locationName: locationName
        )

        modelContext.insert(status)
        statuses.insert(status, at: 0)

        // Save locally first for immediate UI update
        try modelContext.save()

        // Update widget immediately
        updateWidget()

        do {
            // Sync to Supabase
            let serverID = try await StatusAPI(client: supabaseClient).createStatus(status: status)
            status.serverID = serverID
            try modelContext.save()

            // Track analytics
            PostHogManager.shared.track("check_in_performed", properties: [
                "status_type": type.rawValue,
                "trigger_type": trigger.rawValue,
                "group_id": currentGroup.id.uuidString
            ])

        } catch {
            // Rollback on error
            modelContext.delete(status)
            statuses.removeAll { $0.id == status.id }
            throw error
        }
    }

    // MARK: - Tasks

    func addTask(title: String, assignedTo: UUID? = nil) async throws {
        guard let currentUser = currentUser, let currentGroup = currentGroup else {
            throw PulseError.userNotAuthenticated
        }

        let task = TaskItem(
            groupID: currentGroup.id,
            createdByUserID: currentUser.id,
            assignedToUserID: assignedTo,
            title: title
        )

        modelContext.insert(task)
        tasks.append(task)
        try modelContext.save()

        // Update widget
        updateWidget()

        do {
            let serverID = try await TaskAPI(client: supabaseClient).createTask(task: task)
            task.serverID = serverID
            try modelContext.save()

            PostHogManager.shared.track("task_added", properties: [
                "group_id": currentGroup.id.uuidString
            ])
        } catch {
            modelContext.delete(task)
            tasks.removeAll { $0.id == task.id }
            throw error
        }
    }

    func toggleTask(_ task: TaskItem) async throws {
        guard let currentUser = currentUser else {
            throw PulseError.userNotAuthenticated
        }

        let wasCompleted = task.completed
        task.toggle(completedBy: currentUser.id)
        try modelContext.save()

        // Update widget
        updateWidget()

        do {
            try await TaskAPI(client: supabaseClient).updateTask(task: task)

            PostHogManager.shared.track(
                task.completed ? "task_completed" : "task_uncompleted",
                properties: [
                    "task_id": task.id.uuidString
                ]
            )
        } catch {
            // Rollback
            task.toggle(completedBy: currentUser.id)
            try modelContext.save()
            updateWidget()
            throw error
        }
    }

    // MARK: - Sync

    func syncFromSupabase() async throws {
        isLoading = true
        defer { isLoading = false }

        await syncStatusesFromSupabase()
        await syncTasksFromSupabase()
        await syncNotesFromSupabase()

        updateWidget()
    }

    private func syncStatusesFromSupabase() async {
        guard let currentGroup = currentGroup else { return }

        do {
            let fetchedStatuses = try await StatusAPI(client: supabaseClient).fetchGroupStatuses(groupID: currentGroup.id)

            // Merge with local data
            for fetchedStatus in fetchedStatuses {
                if let existing = statuses.first(where: { $0.serverID == fetchedStatus.serverID }) {
                    // Update existing
                    existing.statusTypeRaw = fetchedStatus.statusTypeRaw
                    existing.triggerTypeRaw = fetchedStatus.triggerTypeRaw
                    existing.locationName = fetchedStatus.locationName
                } else {
                    // Insert new
                    modelContext.insert(fetchedStatus)
                    statuses.append(fetchedStatus)
                }
            }

            // Sort by creation date
            statuses.sort { $0.createdAt > $1.createdAt }

            try modelContext.save()
        } catch {
            self.error = error
        }
    }

    private func syncTasksFromSupabase() async {
        guard let currentGroup = currentGroup else { return }

        do {
            let fetchedTasks = try await TaskAPI(client: supabaseClient).fetchGroupTasks(groupID: currentGroup.id)

            for fetchedTask in fetchedTasks {
                if let existing = tasks.first(where: { $0.serverID == fetchedTask.serverID }) {
                    existing.title = fetchedTask.title
                    existing.completed = fetchedTask.completed
                    existing.completedAt = fetchedTask.completedAt
                } else {
                    modelContext.insert(fetchedTask)
                    tasks.append(fetchedTask)
                }
            }

            try modelContext.save()
        } catch {
            self.error = error
        }
    }

    private func syncNotesFromSupabase() async {
        // Similar to tasks sync
        // Implementation omitted for brevity
    }

    // MARK: - Widget Update

    func updateWidget() {
        guard let currentUser = currentUser, let currentGroup = currentGroup else {
            return
        }

        // Create snapshot for widget
        let snapshot = PulseSnapshot(
            groupName: currentGroup.name,
            memberCount: currentGroup.memberCount,
            lastUpdated: Date(),
            members: latestStatusPerUser(),
            topTasks: Array(tasks.filter { !$0.completed }.prefix(3))
        )

        do {
            try appGroupStore.writeSnapshot(snapshot)
            appGroupStore.updateLastRefresh(Date())

            // Reload widget timelines
            #if !WIDGET_EXTENSION
            import WidgetKit
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        } catch {
            print("Failed to update widget: \(error)")
        }
    }

    // MARK: - Helpers

    private func loadLocalData() async {
        let userDescriptor = FetchDescriptor<UserProfile>()
        let groupDescriptor = FetchDescriptor<Group>()

        do {
            let users = try modelContext.fetch(userDescriptor)
            currentUser = users.first

            let groups = try modelContext.fetch(groupDescriptor)
            currentGroup = groups.first

            if let group = currentGroup {
                let statusDescriptor = FetchDescriptor<PulseStatus>(
                    predicate: #Predicate { $0.groupID == group.id },
                    sortBy: [SortDescriptor(\PulseStatus.createdAt, order: .reverse)]
                )
                statuses = try modelContext.fetch(statusDescriptor)

                let taskDescriptor = FetchDescriptor<TaskItem>(
                    predicate: #Predicate { $0.groupID == group.id }
                )
                tasks = try modelContext.fetch(taskDescriptor)
            }
        } catch {
            print("Failed to load local data: \(error)")
        }
    }

    private func latestStatusPerUser() -> [MemberStatus] {
        guard let currentGroup = currentGroup else { return [] }

        var latestStatuses: [UUID: PulseStatus] = [:]

        for status in statuses where status.groupID == currentGroup.id {
            if let existing = latestStatuses[status.userID] {
                if status.createdAt > existing.createdAt {
                    latestStatuses[status.userID] = status
                }
            } else {
                latestStatuses[status.userID] = status
            }
        }

        return latestStatuses.map { userID, status in
            MemberStatus(
                id: userID,
                displayName: "User",  // TODO: Fetch from user profiles
                emoji: "👤",
                statusType: status.statusType.rawValue,
                statusText: status.statusType.displayText,
                locationName: status.locationName,
                timestamp: status.createdAt,
                minutesAgo: Int(Date().timeIntervalSince(status.createdAt) / 60)
            )
        }
    }

    private func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}

// MARK: - Errors

enum PulseError: LocalizedError {
    case userNotAuthenticated
    case groupNotFound
    case syncFailed

    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated"
        case .groupNotFound:
            return "Group not found"
        case .syncFailed:
            return "Failed to sync with server"
        }
    }
}
