import Foundation
import Speech
import AVFoundation

// MARK: - Speech Recognition Manager
// Converts voice messages to text using iOS Speech framework

@MainActor
class SpeechRecognitionManager: ObservableObject {
    // MARK: - Singleton

    static let shared = SpeechRecognitionManager()

    // MARK: - Published Properties

    @Published var isTranscribing = false
    @Published var error: SpeechError?

    // MARK: - Private Properties

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechURLRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // MARK: - Initialization

    init() {
        // Initialize with device locale
        speechRecognizer = SFSpeechRecognizer()

        // Check if speech recognition is available
        guard speechRecognizer != nil else {
            error = .notAvailable
            return
        }
    }

    // MARK: - Public Methods

    /// Request speech recognition authorization
    func requestAuthorization() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    switch status {
                    case .authorized:
                        continuation.resume(returning: true)
                    case .denied:
                        self.error = .permissionDenied
                        continuation.resume(returning: false)
                    case .restricted:
                        self.error = .restricted
                        continuation.resume(returning: false)
                    case .notDetermined:
                        continuation.resume(returning: false)
                    @unknown default:
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }

    /// Transcribe audio file to text
    func transcribe(audioURL: URL) async throws -> String {
        // Check authorization
        guard await requestAuthorization() else {
            throw SpeechError.permissionDenied
        }

        // Check if recognizer is available
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw SpeechError.notAvailable
        }

        // Create recognition request
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        request.requiresOnDeviceRecognition = false // Use cloud for better accuracy

        isTranscribing = true

        return try await withCheckedThrowingContinuation { continuation in
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    guard let self = self else { return }

                    if let error = error {
                        self.isTranscribing = false
                        self.error = .recognitionFailed
                        continuation.resume(throwing: SpeechError.recognitionFailed)
                        return
                    }

                    if let result = result, result.isFinal {
                        self.isTranscribing = false
                        let transcript = result.bestTranscription.formattedString
                        continuation.resume(returning: transcript)

                        // Track analytics
                        let segments = result.bestTranscription.segments
                        let wordCount = segments.count
                        let averageConfidence = Double(segments.map { Double($0.confidence) }.reduce(0, +) / Double(max(wordCount, 1)))
                        PostHogManager.shared.track(
                            .voiceMessageTranscribed(
                                wordCount: wordCount,
                                confidence: averageConfidence
                            )
                        )
                    }
                }
            }
        }
    }

    /// Transcribe with progress updates
    func transcribeWithProgress(audioURL: URL, onProgress: @escaping (String) -> Void) async throws -> String {
        // Check authorization
        guard await requestAuthorization() else {
            throw SpeechError.permissionDenied
        }

        // Check if recognizer is available
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw SpeechError.notAvailable
        }

        // Create recognition request
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false

        isTranscribing = true

        return try await withCheckedThrowingContinuation { continuation in
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    guard let self = self else { return }

                    if let error = error {
                        self.isTranscribing = false
                        self.error = .recognitionFailed
                        continuation.resume(throwing: SpeechError.recognitionFailed)
                        return
                    }

                    if let result = result {
                        let transcript = result.bestTranscription.formattedString

                        if result.isFinal {
                            self.isTranscribing = false
                            continuation.resume(returning: transcript)
                        } else {
                            // Send partial result
                            onProgress(transcript)
                        }
                    }
                }
            }
        }
    }

    /// Cancel ongoing transcription
    func cancelTranscription() {
        recognitionTask?.cancel()
        recognitionTask = nil
        isTranscribing = false
    }

    /// Check if speech recognition is available
    var isAvailable: Bool {
        return speechRecognizer?.isAvailable ?? false
    }

    /// Get supported locales for speech recognition
    static func supportedLocales() -> Set<Locale> {
        return SFSpeechRecognizer.supportedLocales()
    }
}

// MARK: - Speech Error

enum SpeechError: LocalizedError {
    case permissionDenied
    case notAvailable
    case restricted
    case recognitionFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Speech recognition permission is required to transcribe voice messages."
        case .notAvailable:
            return "Speech recognition is not available on this device."
        case .restricted:
            return "Speech recognition is restricted on this device."
        case .recognitionFailed:
            return "Failed to transcribe audio. Please try again."
        }
    }
}

// MARK: - Transcript Quality

extension SFTranscription {
    /// Calculate average confidence score
    var averageConfidence: Double {
        guard !segments.isEmpty else { return 0 }
        let sum = segments.reduce(0.0) { $0 + Double($1.confidence) }
        return sum / Double(segments.count)
    }

    /// Check if transcript is high quality (confidence > 0.8)
    var isHighQuality: Bool {
        return averageConfidence > 0.8
    }

    /// Get transcript with timestamps
    var segmentsWithTimestamps: [(text: String, timestamp: TimeInterval)] {
        return segments.map { ($0.substring, $0.timestamp) }
    }
}
