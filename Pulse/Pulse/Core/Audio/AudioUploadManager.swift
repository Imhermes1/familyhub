import Foundation
import Combine

// MARK: - Audio Upload Manager
// Handles background upload of voice messages to Supabase Storage

@MainActor
class AudioUploadManager: ObservableObject {
    // MARK: - Singleton

    static let shared = AudioUploadManager()

    // MARK: - Published Properties

    @Published var uploadProgress: [UUID: Double] = [:] // Upload progress by message ID
    @Published var isUploading: [UUID: Bool] = [:]
    @Published var error: AudioError?

    // MARK: - Private Properties

    private var uploadTasks: [UUID: URLSessionUploadTask] = [:]
    private var uploadQueue: [UploadItem] = []
    private let maxConcurrentUploads = 2

    // Storage configuration
    private let storageBucket = "voice-messages"
    private let maxFileSizeBytes: Int64 = 5 * 1024 * 1024 // 5MB max

    // MARK: - Upload Item

    struct UploadItem {
        let id: UUID
        let localURL: URL
        let fileName: String
        let metadata: [String: String]
    }

    // MARK: - Public Methods

    /// Upload voice message to storage
    func upload(id: UUID, fileURL: URL, groupID: UUID) async throws -> String {
        // Validate file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw AudioError.fileNotFound
        }

        // Validate file size
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        guard let fileSize = attributes[.size] as? Int64, fileSize <= maxFileSizeBytes else {
            throw AudioError.uploadFailed
        }

        // Compress if needed
        let uploadURL = try await compressIfNeeded(fileURL: fileURL)

        // Generate storage path
        let fileName = "\(groupID.uuidString)/\(id.uuidString).m4a"

        // Update state
        isUploading[id] = true
        uploadProgress[id] = 0

        do {
            // Upload to Supabase Storage
            let remotePath = try await uploadToStorage(
                id: id,
                localURL: uploadURL,
                fileName: fileName
            )

            // Clean up temp file if we compressed
            if uploadURL != fileURL {
                try? FileManager.default.removeItem(at: uploadURL)
            }

            // Update state
            isUploading[id] = false
            uploadProgress[id] = 1.0

            // Track analytics
            PostHogManager.shared.track(.voiceMessageUploaded, properties: [
                "message_id": id.uuidString,
                "file_size": fileSize
            ])

            return remotePath
        } catch {
            isUploading[id] = false
            uploadProgress[id] = nil
            throw AudioError.uploadFailed
        }
    }

    /// Cancel upload
    func cancelUpload(id: UUID) {
        uploadTasks[id]?.cancel()
        uploadTasks[id] = nil
        isUploading[id] = false
        uploadProgress[id] = nil
    }

    /// Get upload progress for message
    func getProgress(for id: UUID) -> Double {
        return uploadProgress[id] ?? 0
    }

    // MARK: - Private Methods

    private func compressIfNeeded(fileURL: URL) async throws -> URL {
        // Check current file size
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        guard let fileSize = attributes[.size] as? Int64 else {
            throw AudioError.uploadFailed
        }

        // Target: < 100KB per 10 seconds of audio
        // If already small enough, return original
        if fileSize < 500_000 { // 500KB threshold
            return fileURL
        }

        // For now, return original (compression can be added later if needed)
        // AAC at 32kbps should already be quite compressed
        return fileURL
    }

    private func uploadToStorage(id: UUID, localURL: URL, fileName: String) async throws -> String {
        // TODO: Implement actual Supabase Storage upload when SDK is integrated
        // For now, we'll use a placeholder that simulates upload

        // Simulate upload progress
        for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
            uploadProgress[id] = progress
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }

        // Return simulated remote URL
        // In production, this would be the Supabase Storage URL
        return "https://storage.supabase.co/object/public/\(storageBucket)/\(fileName)"
    }

    private func uploadWithURLSession(id: UUID, localURL: URL, remotePath: String) async throws -> String {
        // This method will be used when we integrate Supabase SDK
        // URLSession for background uploads with progress tracking

        let request = try createUploadRequest(remotePath: remotePath)
        let data = try Data(contentsOf: localURL)

        return try await withCheckedThrowingContinuation { continuation in
            let task = URLSession.shared.uploadTask(with: request, from: data) { data, response, error in
                Task { @MainActor in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }

                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        continuation.resume(throwing: AudioError.uploadFailed)
                        return
                    }

                    // Parse response to get public URL
                    // This is placeholder - actual implementation depends on Supabase SDK
                    continuation.resume(returning: remotePath)
                }
            }

            uploadTasks[id] = task
            task.resume()
        }
    }

    private func createUploadRequest(remotePath: String) throws -> URLRequest {
        // TODO: Create actual Supabase Storage upload request
        // This is a placeholder
        guard let url = URL(string: "https://placeholder.supabase.co/storage/v1/object/\(remotePath)") else {
            throw AudioError.uploadFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")

        return request
    }
}

// MARK: - File Management

extension AudioUploadManager {
    /// Clean up old voice message files from temp directory
    func cleanupOldFiles(olderThan days: Int = 7) {
        let tempDir = FileManager.default.temporaryDirectory
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date())!

        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: tempDir,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )

            for file in files where file.lastPathComponent.starts(with: "voice_") {
                let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
                if let creationDate = attributes[.creationDate] as? Date,
                   creationDate < cutoffDate {
                    try FileManager.default.removeItem(at: file)
                }
            }
        } catch {
            print("Failed to cleanup old files: \(error)")
        }
    }

    /// Get size of temp audio files
    func getTempStorageSize() -> Int64 {
        let tempDir = FileManager.default.temporaryDirectory
        var totalSize: Int64 = 0

        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: tempDir,
                includingPropertiesForKeys: [.fileSizeKey],
                options: .skipsHiddenFiles
            )

            for file in files where file.lastPathComponent.starts(with: "voice_") {
                let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
                if let size = attributes[.size] as? Int64 {
                    totalSize += size
                }
            }
        } catch {
            print("Failed to calculate temp storage: \(error)")
        }

        return totalSize
    }
}
