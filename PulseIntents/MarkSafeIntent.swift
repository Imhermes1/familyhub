import Foundation
import AppIntents
import WidgetKit

struct MarkSafeIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Safe"
    static var description = IntentDescription("Mark yourself as arrived/safe")

    func perform() async throws -> some IntentResult {
        // TODO: Implement actual check-in
        // This would need to:
        // 1. Access App Group to get current user
        // 2. Make API call to Supabase to create status_event
        // 3. Update App Group snapshot
        // 4. Reload widget timeline

        print("MarkSafeIntent performed")

        // Reload all widgets
        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}

struct MarkLeavingIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Leaving"
    static var description = IntentDescription("Mark yourself as leaving")

    func perform() async throws -> some IntentResult {
        print("MarkLeavingIntent performed")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct MarkOnTheWayIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark On The Way"
    static var description = IntentDescription("Mark yourself as on the way")

    func perform() async throws -> some IntentResult {
        print("MarkOnTheWayIntent performed")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
