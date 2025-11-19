import Foundation
import AVFoundation
import Combine

// MARK: - Audio Playback Manager
// Manages voice message playback with queue support

@MainActor
class AudioPlaybackManager: NSObject, ObservableObject {
    // MARK: - Singleton

    static let shared = AudioPlaybackManager()

    // MARK: - Published Properties

    @Published var isPlaying = false
    @Published var currentlyPlayingID: UUID?
    @Published var playbackProgress: Double = 0 // 0 to 1
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var error: AudioError?

    // MARK: - Private Properties

    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    private let audioSession = AVAudioSession.sharedInstance()
    private var playbackQueue: [PlaybackItem] = []

    // MARK: - Playback Item

    struct PlaybackItem {
        let id: UUID
        let url: URL
    }

    // MARK: - Public Methods

    /// Play audio file
    func play(id: UUID, url: URL) async throws {
        // If already playing this file, pause instead
        if currentlyPlayingID == id && isPlaying {
            pause()
            return
        }

        // If playing different file, stop current
        if currentlyPlayingID != id {
            stop()
        }

        // Configure audio session for playback
        try configureAudioSession()

        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            // Try to download from remote URL if it's a web URL
            if url.absoluteString.starts(with: "http") {
                try await downloadAndPlay(id: id, url: url)
                return
            }
            throw AudioError.fileNotFound
        }

        // Create or resume player
        if audioPlayer == nil || currentlyPlayingID != id {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()

            duration = audioPlayer?.duration ?? 0
            currentTime = 0
        }

        // Start playing
        guard audioPlayer?.play() == true else {
            throw AudioError.playbackFailed
        }

        // Update state
        isPlaying = true
        currentlyPlayingID = id

        // Start progress timer
        startProgressTimer()

        // Track analytics
        PostHogManager.shared.track(.voiceMessagePlayed, properties: [
            "message_id": id.uuidString,
            "duration": duration
        ])
    }

    /// Pause playback
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopProgressTimer()
    }

    /// Stop playback completely
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentlyPlayingID = nil
        currentTime = 0
        playbackProgress = 0
        stopProgressTimer()

        // Deactivate audio session
        try? audioSession.setActive(false)
    }

    /// Seek to specific time
    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        player.currentTime = min(max(0, time), duration)
        currentTime = player.currentTime
        updateProgress()
    }

    /// Seek by offset (positive or negative)
    func seek(by offset: TimeInterval) {
        guard let player = audioPlayer else { return }
        let newTime = player.currentTime + offset
        seek(to: newTime)
    }

    /// Queue next message
    func queue(id: UUID, url: URL) {
        playbackQueue.append(PlaybackItem(id: id, url: url))
    }

    /// Clear playback queue
    func clearQueue() {
        playbackQueue.removeAll()
    }

    // MARK: - Private Methods

    private func configureAudioSession() throws {
        try audioSession.setCategory(.playback, mode: .spokenAudio)
        try audioSession.setActive(true)
    }

    private func downloadAndPlay(id: UUID, url: URL) async throws {
        // TODO: Implement download from Supabase Storage
        // For now, throw error
        throw AudioError.fileNotFound
    }

    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateProgress()
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func updateProgress() {
        guard let player = audioPlayer else { return }

        currentTime = player.currentTime
        duration = player.duration

        if duration > 0 {
            playbackProgress = currentTime / duration
        }
    }

    private func playNext() {
        guard !playbackQueue.isEmpty else {
            stop()
            return
        }

        let next = playbackQueue.removeFirst()
        Task {
            try? await play(id: next.id, url: next.url)
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlaybackManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            if flag {
                // Track completion
                if let id = self.currentlyPlayingID {
                    PostHogManager.shared.track(.voiceMessageCompleted, properties: [
                        "message_id": id.uuidString
                    ])
                }

                // Play next in queue or stop
                self.playNext()
            } else {
                self.error = .playbackFailed
                self.stop()
            }
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            self.error = .playbackFailed
            self.stop()
        }
    }
}

// MARK: - Playback Controls

extension AudioPlaybackManager {
    /// Toggle play/pause
    func togglePlayPause(id: UUID, url: URL) async throws {
        if currentlyPlayingID == id && isPlaying {
            pause()
        } else {
            try await play(id: id, url: url)
        }
    }

    /// Skip forward 15 seconds
    func skipForward() {
        seek(by: 15)
    }

    /// Skip backward 15 seconds
    func skipBackward() {
        seek(by: -15)
    }

    /// Check if specific message is currently playing
    func isPlaying(id: UUID) -> Bool {
        return currentlyPlayingID == id && isPlaying
    }
}
