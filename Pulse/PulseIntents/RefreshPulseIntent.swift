// Compiled only for the widget/intents extension
#if WIDGET_EXTENSION
import Foundation
import AppIntents
import WidgetKit

struct RefreshPulseIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Pulse"
    static var description = IntentDescription("Refresh group status from server")

    func perform() async throws -> some IntentResult {
        // TODO: Implement refresh
        // 1. Fetch latest statuses from Supabase
        // 2. Update App Group snapshot
        // 3. Reload widget timeline

        print("RefreshPulseIntent performed")

        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}
#endif
