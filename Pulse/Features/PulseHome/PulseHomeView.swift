import SwiftUI

struct PulseHomeView: View {
    @EnvironmentObject var dataManager: PulseDataManager
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @State private var showManualCheckIn = false

    var glassVariant: Glass {
        reduceTransparency ? .identity : .regular
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Group Summary Card with Liquid Glass
                    GroupSummaryCard(
                        group: dataManager.currentGroup,
                        automationEnabled: dataManager.currentUser?.isAutomationEnabled() ?? false,
                        glassVariant: glassVariant
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Main Check-in Buttons
                    CheckInButtonsView(
                        onCheckIn: { type in
                            Task {
                                do {
                                    try await dataManager.checkIn(type: type)
                                } catch {
                                    print("Check-in failed: \(error)")
                                }
                            }
                        },
                        glassVariant: glassVariant
                    )
                    .padding(.horizontal)

                    // Member Status List (NO glass - flat content)
                    PulseStatusList(statuses: dataManager.statuses)
                }
                .padding(.bottom)
            }
            .navigationTitle("Pulse")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        // Future: Group selector
                    } label: {
                        Label(dataManager.currentGroup?.name ?? "Group", systemImage: "person.3")
                    }
                    .buttonStyle(.glass)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showManualCheckIn = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.blue)
                }
            }
            .sheet(isPresented: $showManualCheckIn) {
                ManualCheckInSheet()
            }
        }
        .onAppear {
            PostHogManager.shared.screen("pulse_home")
        }
    }
}

#Preview {
    PulseHomeView()
        .environmentObject(PulseDataManager.shared)
}
