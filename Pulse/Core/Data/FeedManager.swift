import Foundation
import SwiftUI
import Combine

// MARK: - Feed Manager
// Aggregates all data types into a unified activity feed

@MainActor
class FeedManager: ObservableObject {
    // MARK: - Published Properties

    @Published var feedItems: [FeedItem] = []
    @Published var filteredItems: [FeedItem] = []
    @Published var selectedGroup: UUID?
    @Published var selectedTypeFilter: FeedItemTypeFilter = .all
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false

    // MARK: - Dependencies

    private let dataManager: PulseDataManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(dataManager: PulseDataManager = .shared) {
        self.dataManager = dataManager

        // Setup observers for data changes
        setupObservers()

        // Initial load
        refreshFeed()
    }

    // MARK: - Public Methods

    /// Refresh the entire feed from all data sources
    func refreshFeed() {
        Task {
            isLoading = true
            await buildFeed()
            applyFilters()
            isLoading = false
        }
    }

    /// Set active group filter
    func setGroupFilter(_ groupID: UUID?) {
        selectedGroup = groupID
        applyFilters()
    }

    /// Set type filter
    func setTypeFilter(_ filter: FeedItemTypeFilter) {
        selectedTypeFilter = filter
        applyFilters()
    }

    /// Set search query
    func setSearchQuery(_ query: String) {
        searchQuery = query
        applyFilters()
    }

    /// Clear all filters
    func clearFilters() {
        selectedGroup = nil
        selectedTypeFilter = .all
        searchQuery = ""
        applyFilters()
    }

    /// Get feed items for a specific user
    func getFeedItems(for userID: UUID) -> [FeedItem] {
        feedItems.filtered(by: userID).sortedByTime()
    }

    // MARK: - Private Methods

    private func setupObservers() {
        // Observe data manager changes and refresh feed
        dataManager.$statuses
            .combineLatest(dataManager.$tasks, dataManager.$notes, dataManager.$voiceMessages)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _, _, _, _ in
                self?.refreshFeed()
            }
            .store(in: &cancellables)

        // Observe current group changes
        dataManager.$currentGroup
            .sink { [weak self] group in
                self?.selectedGroup = group?.id
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }

    private func buildFeed() async {
        var items: [FeedItem] = []

        // Get user lookup for display names and emojis
        let userLookup = buildUserLookup()

        // Convert all statuses to feed items
        for status in dataManager.statuses {
            let user = userLookup[status.userID]
            items.append(.fromStatus(
                status,
                userName: user?.name,
                userEmoji: user?.emoji
            ))
        }

        // Convert all tasks to feed items
        for task in dataManager.tasks {
            let user = userLookup[task.createdByID]
            items.append(.fromTask(
                task,
                userName: user?.name,
                userEmoji: user?.emoji
            ))
        }

        // Convert all notes to feed items
        for note in dataManager.notes {
            let user = userLookup[note.createdByID]
            items.append(.fromNote(
                note,
                userName: user?.name,
                userEmoji: user?.emoji
            ))
        }

        // Convert all voice messages to feed items
        for voiceMessage in dataManager.voiceMessages {
            let user = userLookup[voiceMessage.senderID]
            items.append(.fromVoiceMessage(
                voiceMessage,
                userName: user?.name,
                userEmoji: user?.emoji
            ))
        }

        // TODO Phase 3: Add photo shares

        // Sort by time (newest first)
        feedItems = items.sortedByTime()
    }

    private func applyFilters() {
        var items = feedItems

        // Filter by group
        if let groupID = selectedGroup {
            items = items.filtered(by: groupID)
        }

        // Filter by type
        items = items.filtered(by: selectedTypeFilter)

        // Filter by search query
        if !searchQuery.isEmpty {
            items = items.filter { item in
                searchMatches(item, query: searchQuery)
            }
        }

        filteredItems = items
    }

    private func searchMatches(_ item: FeedItem, query: String) -> Bool {
        let lowercasedQuery = query.lowercased()

        // Search in user name
        if let userName = item.userName, userName.lowercased().contains(lowercasedQuery) {
            return true
        }

        // Search in type-specific content
        switch item.type {
        case .location(let status):
            if let location = status.locationName, location.lowercased().contains(lowercasedQuery) {
                return true
            }

        case .task(let task):
            if task.title.lowercased().contains(lowercasedQuery) {
                return true
            }

        case .note(let note):
            if note.content.lowercased().contains(lowercasedQuery) {
                return true
            }

        case .photo(let photo):
            if let caption = photo.caption, caption.lowercased().contains(lowercasedQuery) {
                return true
            }

        case .voiceMessage(let voice):
            if let transcript = voice.transcript, transcript.lowercased().contains(lowercasedQuery) {
                return true
            }
        }

        return false
    }

    private func buildUserLookup() -> [UUID: (name: String, emoji: String)] {
        var lookup: [UUID: (name: String, emoji: String)] = [:]

        // Add current user
        if let currentUser = dataManager.currentUser {
            lookup[currentUser.id] = (currentUser.displayName, currentUser.emoji)
        }

        // Add group members
        // TODO: When we have proper member management, populate this from group members
        // For now, we'll just have the current user

        return lookup
    }
}

// MARK: - Feed Statistics

extension FeedManager {
    /// Get count of feed items by type
    func getCountByType() -> [FeedItemTypeFilter: Int] {
        var counts: [FeedItemTypeFilter: Int] = [:]

        for filter in FeedItemTypeFilter.allCases {
            if filter == .all {
                counts[filter] = feedItems.count
            } else {
                counts[filter] = feedItems.filtered(by: filter).count
            }
        }

        return counts
    }

    /// Get activity count for today
    func getTodayActivityCount() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return feedItems.filter { item in
            calendar.isDate(item.timestamp, inSameDayAs: today)
        }.count
    }

    /// Get most active user
    func getMostActiveUser() -> (userID: UUID, count: Int)? {
        let userCounts = Dictionary(grouping: feedItems, by: { $0.userID })
            .mapValues { $0.count }

        guard let (userID, count) = userCounts.max(by: { $0.value < $1.value }) else {
            return nil
        }

        return (userID, count)
    }
}

// MARK: - Feed Pagination

extension FeedManager {
    /// Load more items (for infinite scroll)
    func loadMore() async {
        // TODO: Implement pagination when we have backend integration
        // For now, all items are loaded at once
    }

    /// Check if there are more items to load
    var hasMore: Bool {
        // TODO: Implement when we have pagination
        return false
    }
}
