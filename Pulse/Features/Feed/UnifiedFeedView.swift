import SwiftUI

// MARK: - Unified Feed View
// Main screen showing all activity in a beautiful timeline

struct UnifiedFeedView: View {
    @EnvironmentObject var dataManager: PulseDataManager
    @StateObject private var feedManager: FeedManager
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency

    @State private var showingQuickCheckIn = false
    @State private var showingQuickNote = false
    @State private var showingQuickTask = false
    @State private var showingVoiceRecord = false
    @State private var showingSettings = false
    @State private var selectedMember: UUID?

    init() {
        _feedManager = StateObject(wrappedValue: FeedManager())
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // Main content
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        // Hero Status Card (pinned at top)
                        HeroStatusCard()
                            .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                            .padding(.top, DesignSystem.Spacing.xs)
                            .onTapGesture {
                                selectedMember = dataManager.currentUser?.id
                            }

                        // Feed content
                        if feedManager.isLoading {
                            LoadingState()
                                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                        } else if feedManager.filteredItems.isEmpty {
                            emptyState
                                .padding(.top, DesignSystem.Spacing.xxl)
                        } else {
                            feedItems
                                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                        }
                    }
                    .padding(.bottom, 100) // Space for FAB
                }
                .refreshable {
                    await refreshFeed()
                }

                // Floating Action Button
                FloatingActionButton(
                    onCheckIn: { showingQuickCheckIn = true },
                    onNote: { showingQuickNote = true },
                    onTask: { showingQuickTask = true },
                    onVoice: { showingVoiceRecord = true }
                )
                .padding(.trailing, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.md)
            }
            .navigationTitle("Family")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    GroupSwitcher()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: DesignSystem.IconSize.medium))
                    }
                    .buttonStyle(.glass)
                }
            }
            .sheet(isPresented: $showingQuickCheckIn) {
                QuickCheckInSheet()
            }
            .sheet(isPresented: $showingQuickNote) {
                QuickNoteSheet()
            }
            .sheet(isPresented: $showingQuickTask) {
                QuickTaskSheet()
            }
            .sheet(isPresented: $showingVoiceRecord) {
                VoiceRecordSheet()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsViewRedesign()
            }
            .sheet(item: $selectedMember) { memberID in
                MemberDetailSheet(memberID: memberID)
            }
        }
        .onAppear {
            PostHogManager.shared.screen("unified_feed")
            feedManager.refreshFeed()
        }
        .environmentObject(feedManager)
    }

    // MARK: - Feed Items

    @ViewBuilder
    private var feedItems: some View {
        LazyVStack(spacing: DesignSystem.Spacing.md) {
            ForEach(feedManager.filteredItems) { item in
                feedItemCard(for: item)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .animation(DesignSystem.Animation.spring, value: feedManager.filteredItems.count)
            }
        }
    }

    @ViewBuilder
    private func feedItemCard(for item: FeedItem) -> some View {
        switch item.type {
        case .location(let status):
            LocationCard(
                status: status,
                userName: item.userName,
                userEmoji: item.userEmoji
            )

        case .task(let task):
            TaskCard(
                task: task,
                userName: item.userName,
                userEmoji: item.userEmoji,
                onToggle: { toggledTask in
                    Task {
                        try? await dataManager.toggleTask(toggledTask)
                    }
                }
            )

        case .note(let note):
            NoteCard(
                note: note,
                userName: item.userName,
                userEmoji: item.userEmoji
            )

        case .voiceMessage(let message):
            VoiceMessageCard(
                message: message,
                userName: item.userName,
                userEmoji: item.userEmoji
            )

        case .photo:
            // TODO: Phase 3 - PhotoCard
            EmptyView()
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        if let currentGroup = dataManager.currentGroup {
            EmptyState.noActivity {
                showingQuickCheckIn = true
            }
        } else {
            EmptyState.noGroups {
                // TODO: Navigate to group creation
            }
        }
    }

    // MARK: - Actions

    private func refreshFeed() async {
        HapticManager.shared.impact(.light)
        await feedManager.refreshFeed()
    }
}

// MARK: - Preview
#Preview {
    UnifiedFeedView()
        .environmentObject(PulseDataManager.shared)
}
