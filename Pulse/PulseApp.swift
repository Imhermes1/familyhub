import SwiftUI
import SwiftData

@main
struct PulseApp: App {
    @StateObject private var dataManager = PulseDataManager.shared

    let modelContainer: ModelContainer

    init() {
        // Configure SwiftData model container
        do {
            let schema = Schema([
                UserProfile.self,
                Group.self,
                PulseStatus.self,
                TaskItem.self,
                Note.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .identifier("group.com.yourcompany.pulse")
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // Initialize PostHog
        PostHogManager.shared.initialize()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(modelContainer)
                .environmentObject(dataManager)
                .onAppear {
                    Task {
                        await dataManager.initialize(modelContext: modelContainer.mainContext)
                        PostHogManager.shared.track("app_opened")
                    }
                }
        }
    }
}
