import SwiftUI

struct RootView: View {
    @EnvironmentObject var dataManager: PulseDataManager
    @State private var isAuthenticated = false
    @State private var hasCompletedOnboarding = false

    #if DEBUG
    private let forceSkipAuth = true
    #else
    private let forceSkipAuth = false
    #endif

    var body: some View {
        SwiftUI.Group {
            if !isAuthenticated {
                WelcomeView()
            } else if !hasCompletedOnboarding {
                ProfileSetupView()
            } else {
                MainTabView()
            }
        }
        .onAppear {
            if forceSkipAuth {
                isAuthenticated = true
                hasCompletedOnboarding = true
            } else {
                checkAuthState()
            }
        }
    }

    private func checkAuthState() {
        // Check Supabase auth state
        Task {
            isAuthenticated = await dataManager.isUserAuthenticated()
            if isAuthenticated {
                hasCompletedOnboarding = await dataManager.hasCompletedOnboarding()
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        // New unified feed view - no tabs, single beautiful timeline
        UnifiedFeedView()
    }
}

#Preview {
    RootView()
        .environmentObject(PulseDataManager.shared)
}
