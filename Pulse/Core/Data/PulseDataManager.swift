import Foundation
import SwiftData
import Combine
#if !WIDGET_EXTENSION
import WidgetKit
#endif

@MainActor
class PulseDataManager: ObservableObject {
    static let shared = PulseDataManager()

    #if DEBUG
    private let isDebugBypass = true
    #else
    private let isDebugBypass = false
    #endif

    // Dependencies
    private(set) var supabaseClient: SupabaseClient?
    private(set) var modelContext: ModelContext!
    private(set) var appGroupStore: AppGroupStore!
    private(set) var realtimeManager: RealtimeManager!

    // Published state
    @Published var currentUser: UserProfile?
    @Published var currentGroup: Group?
    @Published var statuses: [PulseStatus] = []
    @Published var tasks: [TaskItem] = []
    @Published var notes: [Note] = []
    @Published var voiceMessages: [VoiceMessageModel] = []
    @Published var isLoading = false
    @Published var error: Error?

    private init() {}

    func initialize(modelContext: ModelContext) async {
        self.modelContext = modelContext
        self.supabaseClient = SupabaseClient()
        self.appGroupStore = isDebugBypass ? nil : AppGroupStore()

        // Load current user and group from SwiftData
        await loadLocalData()

        // Dev stub data to bypass auth/backend while testing UI
        #if DEBUG
        if currentUser == nil || currentGroup == nil {
            seedDevUserAndGroup()
        }
        #endif

        // Initialize realtime subscriptions if authenticated
        if let currentUser = currentUser, let currentGroup = currentGroup, let supabaseClient = supabaseClient {
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
        #if DEBUG
        return true
        #endif
        do {
            guard let supabaseClient else { return false }
            return try await supabaseClient.isAuthenticated()
        } catch {
            return false
        }
    }

    // MARK: - Dev Seed

    private func seedDevUserAndGroup() {
        let user = UserProfile(displayName: "Test User", emoji: "😀")
        let group = Group(name: "Lumora Test", inviteCode: "DEV123", memberCount: 3)

        modelContext.insert(user)
        modelContext.insert(group)

        currentUser = user
        currentGroup = group

        do {
            try modelContext.save()
        } catch {
            print("Failed to seed dev data: \(error)")
        }
    }

    func hasCompletedOnboarding() async -> Bool {
        return currentUser != nil && currentGroup != nil
    }

    func signIn(email: String) async throws {
        try await supabaseClient?.signInWithMagicLink(email: email)
    }

    func signOut() async throws {
        try await supabaseClient?.signOut()
        currentUser = nil
        currentGroup = nil
        statuses = []
        tasks = []
        notes = []
    }

    // MARK: - Profile Setup

    func createUserProfile(displayName: String, emoji: String) async throws {
        let authUserID = try await supabaseClient?.getCurrentUserID() ?? UUID()

        let profile = UserProfile(
            authUserID: authUserID,
            displayName: displayName,
            emoji: emoji
        )

        modelContext.insert(profile)
        try modelContext.save()

        // Sync to Supabase
        if let supabaseClient {
            try await UserAPI(client: supabaseClient).createUser(profile: profile)
        }

        currentUser = profile
    }

    func createGroup(name: String) async throws {
        if isDebugBypass && currentUser == nil {
            seedDevUserAndGroup()
        }

        if isDebugBypass && currentUser == nil {
            seedDevUserAndGroup()
        }

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
        if let supabaseClient {
            try await GroupAPI(client: supabaseClient).createGroup(group: group, creatorID: currentUser.id)
        }

        currentGroup = group
    }

    func joinGroup(inviteCode: String) async throws {
        if isDebugBypass && currentUser == nil {
            seedDevUserAndGroup()
        }

        guard let currentUser = currentUser else {
            throw PulseError.userNotAuthenticated
        }

        // Fetch group from Supabase
        guard let supabaseClient else { return }
        let group = try await GroupAPI(client: supabaseClient).joinGroup(inviteCode: inviteCode, userID: currentUser.id)

        modelContext.insert(group)
        try modelContext.save()

        currentGroup = group
    }

    // MARK: - Check-in

    func checkIn(type: StatusType, trigger: TriggerType = .manual, locationName: String? = nil) async throws {
        if isDebugBypass && (currentUser == nil || currentGroup == nil) {
            seedDevUserAndGroup()
        }

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
            if let supabaseClient {
                let serverID = try await StatusAPI(client: supabaseClient).createStatus(status: status)
                status.serverID = serverID
            }
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
            if let supabaseClient {
                let serverID = try await TaskAPI(client: supabaseClient).createTask(task: task)
                task.serverID = serverID
            }
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
        if isDebugBypass && currentUser == nil {
            seedDevUserAndGroup()
        }

        guard let currentUser = currentUser else {
            throw PulseError.userNotAuthenticated
        }

        let wasCompleted = task.completed
        task.toggle(completedBy: currentUser.id)
        try modelContext.save()

        // Update widget
        updateWidget()

        do {
            if let supabaseClient {
                try await TaskAPI(client: supabaseClient).updateTask(task: task)
            }

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

    // MARK: - Voice Messages

    func sendVoiceMessage(_ message: VoiceMessageModel) async throws {
        guard let currentUser = currentUser, let currentGroup = currentGroup else {
            throw PulseError.userNotAuthenticated
        }

        // Save locally first (optimistic update)
        modelContext.insert(message)
        voiceMessages.insert(message, at: 0)
        try modelContext.save()

        // Upload audio file
        if let localPath = message.localFileURL, let url = URL(string: localPath) {
            Task {
                do {
                    message.uploadStatus = .uploading
                    try modelContext.save()

                    // Upload to storage
                    let remotePath = try await AudioUploadManager.shared.upload(
                        id: message.id,
                        fileURL: url,
                        groupID: currentGroup.id
                    )

                    message.audioURL = remotePath
                    message.uploadStatus = .completed
                    try modelContext.save()

                    // TODO: Sync to Supabase database
                    // if let supabaseClient {
                    //     let serverID = try await VoiceMessageAPI(client: supabaseClient).create(message: message)
                    //     message.serverID = serverID
                    // }

                    // Track analytics
                    PostHogManager.shared.track(.voiceMessageSent, properties: [
                        "duration": message.duration,
                        "has_transcript": message.transcript != nil,
                        "recipient_count": message.recipientIDs.count
                    ])
                } catch {
                    message.uploadStatus = .failed
                    try? modelContext.save()
                    print("Voice message upload failed: \(error)")
                }
            }
        }
    }

    func deleteVoiceMessage(_ message: VoiceMessageModel) throws {
        // Delete local file
        message.deleteLocalFile()

        // Remove from list
        voiceMessages.removeAll { $0.id == message.id }

        // Delete from SwiftData
        modelContext.delete(message)
        try modelContext.save()

        // TODO: Delete from Supabase
    }

    func markVoiceMessageAsPlayed(_ message: VoiceMessageModel) throws {
        message.isPlayed = true
        message.playedAt = Date()
        try modelContext.save()

        // TODO: Sync to Supabase
    }

    // MARK: - Notes

    func addNote(content: String) async throws {
        guard let currentUser = currentUser, let currentGroup = currentGroup else {
            throw PulseError.userNotAuthenticated
        }

        let note = Note(
            groupID: currentGroup.id,
            createdByID: currentUser.id,
            content: content
        )

        modelContext.insert(note)
        notes.append(note)
        try modelContext.save()

        // TODO: Sync to Supabase

        PostHogManager.shared.track(.noteCreated, properties: [
            "content_length": content.count
        ])
    }

    // MARK: - Sync

    func syncFromSupabase() async throws {
        isLoading = true
        defer { isLoading = false }

        await syncStatusesFromSupabase()
        await syncTasksFromSupabase()
        await syncNotesFromSupabase()
        await syncVoiceMessagesFromSupabase()

        updateWidget()
    }

    private func syncStatusesFromSupabase() async {
        guard let currentGroup = currentGroup else { return }

        do {
            guard let supabaseClient else { return }
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
            guard let supabaseClient else { return }
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

    private func syncVoiceMessagesFromSupabase() async {
        guard let currentGroup = currentGroup else { return }

        // TODO: Implement when Supabase SDK is integrated
        // do {
        //     guard let supabaseClient else { return }
        //     let fetchedMessages = try await VoiceMessageAPI(client: supabaseClient).fetchGroupMessages(groupID: currentGroup.id)
        //
        //     for fetchedMessage in fetchedMessages {
        //         if !voiceMessages.contains(where: { $0.serverID == fetchedMessage.serverID }) {
        //             modelContext.insert(fetchedMessage)
        //             voiceMessages.append(fetchedMessage)
        //         }
        //     }
        //
        //     voiceMessages.sort { $0.createdAt > $1.createdAt }
        //     try modelContext.save()
        // } catch {
        //     self.error = error
        // }
    }

    // MARK: - Widget Update

    func updateWidget() {
        // Skip widget writes in debug when app group entitlement isn't present
        guard !isDebugBypass, let currentUser = currentUser, let currentGroup = currentGroup else { return }

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
                let groupID = group.id

                let statusDescriptor = FetchDescriptor<PulseStatus>(
                    predicate: #Predicate { $0.groupID == groupID },
                    sortBy: [SortDescriptor(\PulseStatus.createdAt, order: .reverse)]
                )
                statuses = try modelContext.fetch(statusDescriptor)

                let taskDescriptor = FetchDescriptor<TaskItem>(
                    predicate: #Predicate { $0.groupID == groupID }
                )
                tasks = try modelContext.fetch(taskDescriptor)

                let voiceMessageDescriptor = FetchDescriptor<VoiceMessageModel>(
                    predicate: #Predicate { $0.groupID == groupID },
                    sortBy: [SortDescriptor(\VoiceMessageModel.createdAt, order: .reverse)]
                )
                voiceMessages = try modelContext.fetch(voiceMessageDescriptor)
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
