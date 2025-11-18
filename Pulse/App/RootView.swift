import SwiftUI

struct RootView: View {
    @EnvironmentObject var dataManager: PulseDataManager
    @State private var isAuthenticated = false
    @State private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if !isAuthenticated {
                WelcomeView()
            } else if !hasCompletedOnboarding {
                ProfileSetupView()
            } else {
                MainTabView()
            }
        }
        .onAppear {
            checkAuthState()
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
        TabView {
            PulseHomeView()
                .tabItem {
                    Label("Pulse", systemImage: "waveform.path.ecg")
                }

            TasksView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(PulseDataManager.shared)
}
