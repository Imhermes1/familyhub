import Foundation
import UserNotifications
import UIKit

/// Manages local and push notifications
class NotificationManager {
    static let shared = NotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permission Management

    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])

            await MainActor.run {
                PostHogManager.shared.track(
                    granted ? "permission_granted" : "permission_denied",
                    properties: ["permission_type": "notifications"]
                )
            }

            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }

    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    var hasPermission: Bool {
        get async {
            let status = await checkPermissionStatus()
            return status == .authorized || status == .provisional
        }
    }

    // MARK: - Local Notifications

    func scheduleCheckInReminder(in minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Check In Reminder"
        content.body = "Don't forget to update your status"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let request = UNNotificationRequest(identifier: "checkInReminder", content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    func cancelNotification(withIdentifier identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Badge Management

    func setBadgeCount(_ count: Int) {
        Task { @MainActor in
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }

    func clearBadge() {
        setBadgeCount(0)
    }

    // MARK: - Push Notification Token

    func registerForPushNotifications() {
        Task { @MainActor in
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func handleDeviceToken(_ deviceToken: Data) -> String {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        return token
    }

    // MARK: - Notification Handling

    func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        // Deep linking logic
        if let statusID = userInfo["status_id"] as? String {
            print("Open status: \(statusID)")
            // Navigate to status detail
        } else if let groupID = userInfo["group_id"] as? String {
            print("Open group: \(groupID)")
            // Navigate to group view
        }
    }
}

// MARK: - Notification Content Extensions

extension NotificationManager {
    /// Creates a notification for a new check-in from a group member
    func sendCheckInNotification(memberName: String, status: String, groupName: String) {
        let content = UNMutableNotificationContent()
        content.title = groupName
        content.body = "\(memberName) \(status)"
        content.sound = .default
        content.categoryIdentifier = "CHECK_IN"

        // Deliver immediately
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }

    /// Creates a notification for a new task assignment
    func sendTaskNotification(taskTitle: String, assignedBy: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Task"
        content.body = "\(assignedBy) assigned you: \(taskTitle)"
        content.sound = .default
        content.categoryIdentifier = "TASK"

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }
}

// MARK: - Notification Categories

extension NotificationManager {
    func registerNotificationCategories() {
        // Check-in category with quick actions
        let checkInAction = UNNotificationAction(
            identifier: "MARK_SAFE",
            title: "I'm Safe",
            options: [.foreground]
        )

        let checkInCategory = UNNotificationCategory(
            identifier: "CHECK_IN",
            actions: [checkInAction],
            intentIdentifiers: [],
            options: []
        )

        // Task category
        let completeTaskAction = UNNotificationAction(
            identifier: "COMPLETE_TASK",
            title: "Mark Complete",
            options: []
        )

        let taskCategory = UNNotificationCategory(
            identifier: "TASK",
            actions: [completeTaskAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([checkInCategory, taskCategory])
    }
}
