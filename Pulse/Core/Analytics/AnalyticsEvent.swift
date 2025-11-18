import Foundation

/// Type-safe analytics event tracking
enum AnalyticsEvent {
    case appOpened(sessionID: String, userID: String, groupID: String)
    case checkInPerformed(statusType: String, triggerType: String, groupID: String)
    case autoUpdateTriggered(source: String, statusType: String)
    case taskAdded(groupID: String, assignedTo: String?)
    case taskCompleted(taskID: String, completedBy: String, timeToCompleteHours: Int?)
    case taskUncompleted(taskID: String)
    case widgetActionUsed(actionType: String, widgetSize: String)
    case settingsChanged(key: String, newValue: Any)
    case permissionRequested(type: String)
    case permissionGranted(type: String)
    case permissionDenied(type: String)
    case groupCreated(groupID: String, memberCount: Int)
    case groupJoined(groupID: String, inviteCode: String)
    case noteCreated(noteType: String)
    case screenViewed(screenName: String)
    case errorOccurred(error: String, context: String)

    var name: String {
        switch self {
        case .appOpened:
            return "app_opened"
        case .checkInPerformed:
            return "check_in_performed"
        case .autoUpdateTriggered:
            return "auto_update_triggered"
        case .taskAdded:
            return "task_added"
        case .taskCompleted:
            return "task_completed"
        case .taskUncompleted:
            return "task_uncompleted"
        case .widgetActionUsed:
            return "widget_action_used"
        case .settingsChanged:
            return "settings_changed"
        case .permissionRequested:
            return "permission_requested"
        case .permissionGranted:
            return "permission_granted"
        case .permissionDenied:
            return "permission_denied"
        case .groupCreated:
            return "group_created"
        case .groupJoined:
            return "group_joined"
        case .noteCreated:
            return "note_created"
        case .screenViewed:
            return "screen_viewed"
        case .errorOccurred:
            return "error_occurred"
        }
    }

    var properties: [String: Any] {
        switch self {
        case .appOpened(let sessionID, let userID, let groupID):
            return [
                "session_id": sessionID,
                "user_id": userID,
                "group_id": groupID
            ]

        case .checkInPerformed(let statusType, let triggerType, let groupID):
            return [
                "status_type": statusType,
                "trigger_type": triggerType,
                "group_id": groupID
            ]

        case .autoUpdateTriggered(let source, let statusType):
            return [
                "trigger_source": source,
                "status_type": statusType
            ]

        case .taskAdded(let groupID, let assignedTo):
            var props: [String: Any] = ["group_id": groupID]
            if let assignedTo = assignedTo {
                props["assigned_to"] = assignedTo
            }
            return props

        case .taskCompleted(let taskID, let completedBy, let timeToComplete):
            var props: [String: Any] = [
                "task_id": taskID,
                "completed_by": completedBy
            ]
            if let hours = timeToComplete {
                props["time_to_complete_hours"] = hours
            }
            return props

        case .taskUncompleted(let taskID):
            return ["task_id": taskID]

        case .widgetActionUsed(let actionType, let widgetSize):
            return [
                "action_type": actionType,
                "widget_size": widgetSize
            ]

        case .settingsChanged(let key, let newValue):
            return [
                "setting_key": key,
                "new_value": newValue
            ]

        case .permissionRequested(let type):
            return ["permission_type": type]

        case .permissionGranted(let type):
            return ["permission_type": type]

        case .permissionDenied(let type):
            return ["permission_type": type]

        case .groupCreated(let groupID, let memberCount):
            return [
                "group_id": groupID,
                "member_count": memberCount
            ]

        case .groupJoined(let groupID, let inviteCode):
            return [
                "group_id": groupID,
                "invite_code": inviteCode
            ]

        case .noteCreated(let noteType):
            return ["note_type": noteType]

        case .screenViewed(let screenName):
            return ["screen_name": screenName]

        case .errorOccurred(let error, let context):
            return [
                "error": error,
                "context": context
            ]
        }
    }

    func track() {
        PostHogManager.shared.track(name, properties: properties)
    }
}

// MARK: - Convenience Extensions

extension PostHogManager {
    func track(_ event: AnalyticsEvent) {
        track(event.name, properties: event.properties)
    }
}
