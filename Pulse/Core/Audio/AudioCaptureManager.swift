import Foundation
import AVFoundation
import Combine

// MARK: - Audio Capture Manager
// Manages voice message recording with microphone permissions and background support

@MainActor
class AudioCaptureManager: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published var isRecording = false
    @Published var currentRecordingURL: URL?
    @Published var recordingDuration: TimeInterval = 0
    @Published var audioLevel: Float = 0 // For waveform visualization
    @Published var error: AudioError?

    // MARK: - Private Properties

    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var meteringTimer: Timer?
    private let audioSession = AVAudioSession.sharedInstance()

    // Audio settings optimized for voice (low latency, small file size)
    private let audioSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 16000, // 16kHz for voice (vs 44.1kHz for music)
        AVNumberOfChannelsKey: 1, // Mono
        AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
        AVEncoderBitRateKey: 32000 // 32kbps for ~240KB per minute
    ]

    // MARK: - Initialization

    override init() {
        super.init()
    }

    // MARK: - Public Methods

    /// Request microphone permission
    func requestPermission() async -> Bool {
        switch audioSession.recordPermission {
        case .granted:
            return true
        case .denied:
            error = .permissionDenied
            return false
        case .undetermined:
            return await withCheckedContinuation { continuation in
                audioSession.requestRecordPermission { granted in
                    Task { @MainActor in
                        if !granted {
                            self.error = .permissionDenied
                        }
                        continuation.resume(returning: granted)
                    }
                }
            }
        @unknown default:
            return false
        }
    }

    /// Start recording voice message
    func startRecording() async throws -> URL {
        // Request permission first
        guard await requestPermission() else {
            throw AudioError.permissionDenied
        }

        // Configure audio session
        try configureAudioSession()

        // Generate file URL
        let fileName = "voice_\(UUID().uuidString).m4a"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        // Create and start recorder
        audioRecorder = try AVAudioRecorder(url: fileURL, settings: audioSettings)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.prepareToRecord()

        guard audioRecorder?.record() == true else {
            throw AudioError.recordingFailed
        }

        // Update state
        isRecording = true
        currentRecordingURL = fileURL
        recordingDuration = 0

        // Start timers
        startTimers()

        // Track analytics
        PostHogManager.shared.track(.voiceRecordingStarted)

        return fileURL
    }

    /// Stop recording and return the file URL
    func stopRecording() -> URL? {
        guard isRecording, let recorder = audioRecorder else {
            return nil
        }

        // Stop recording
        recorder.stop()

        // Stop timers
        stopTimers()

        // Update state
        isRecording = false
        let url = currentRecordingURL

        // Track analytics
        PostHogManager.shared.track(.voiceRecordingStopped(duration: recordingDuration))

        // Deactivate audio session
        try? audioSession.setActive(false)

        return url
    }

    /// Cancel recording and delete file
    func cancelRecording() {
        guard isRecording else { return }

        audioRecorder?.stop()
        stopTimers()

        // Delete temp file
        if let url = currentRecordingURL {
            try? FileManager.default.removeItem(at: url)
        }

        // Reset state
        isRecording = false
        currentRecordingURL = nil
        recordingDuration = 0
        audioLevel = 0

        // Deactivate audio session
        try? audioSession.setActive(false)

        // Track analytics
        PostHogManager.shared.track(.voiceRecordingCancelled)
    }

    /// Get duration of an audio file
    func getDuration(of url: URL) -> TimeInterval? {
        let asset = AVURLAsset(url: url)
        return CMTimeGetSeconds(asset.duration)
    }

    // MARK: - Private Methods

    private func configureAudioSession() throws {
        try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func startTimers() {
        // Duration timer (updates every 0.1s)
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.recordingDuration += 0.1
            }
        }

        // Metering timer for audio levels (updates every 0.05s for smooth visualization)
        meteringTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateAudioLevel()
            }
        }
    }

    private func stopTimers() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        meteringTimer?.invalidate()
        meteringTimer = nil
    }

    private func updateAudioLevel() {
        guard let recorder = audioRecorder, recorder.isRecording else {
            audioLevel = 0
            return
        }

        recorder.updateMeters()

        // Get average power for channel 0 (mono)
        let power = recorder.averagePower(forChannel: 0)

        // Convert from decibels (-160 to 0) to normalized value (0 to 1)
        // -160 dB is silence, 0 dB is max
        let minDb: Float = -60
        let normalizedLevel = max(0, min(1, 1 - (abs(power) / abs(minDb))))

        audioLevel = normalizedLevel
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioCaptureManager: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if !flag {
                self.error = .recordingFailed
            }
        }
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            self.error = .recordingFailed
        }
    }
}

// MARK: - Audio Error

enum AudioError: LocalizedError {
    case permissionDenied
    case recordingFailed
    case playbackFailed
    case fileNotFound
    case uploadFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission is required to record voice messages."
        case .recordingFailed:
            return "Failed to record audio. Please try again."
        case .playbackFailed:
            return "Failed to play audio. The file may be corrupted."
        case .fileNotFound:
            return "Audio file not found."
        case .uploadFailed:
            return "Failed to upload voice message. Please check your connection."
        }
    }
}
