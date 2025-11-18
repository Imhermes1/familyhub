import Foundation
import AppIntents
import WidgetKit

struct TickTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Task"
    static var description = IntentDescription("Toggle task completion")

    @Parameter(title: "Task ID")
    var taskID: UUID

    init() {
        self.taskID = UUID()
    }

    init(taskID: UUID) {
        self.taskID = taskID
    }

    func perform() async throws -> some IntentResult {
        // TODO: Implement task toggle
        // 1. Load task from App Group or make API call
        // 2. Toggle completion status
        // 3. Update Supabase
        // 4. Update App Group snapshot
        // 5. Reload widget

        print("TickTaskIntent performed for task: \(taskID)")

        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}
