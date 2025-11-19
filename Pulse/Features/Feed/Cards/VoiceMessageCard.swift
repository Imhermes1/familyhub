import SwiftUI

// MARK: - Voice Message Card
// Beautiful card for voice messages in the feed

struct VoiceMessageCard: View {
    let message: VoiceMessageModel
    let userName: String?
    let userEmoji: String?

    @StateObject private var playbackManager = AudioPlaybackManager.shared
    @State private var showTranscript = false

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                // Header with avatar and user info
                HStack(spacing: DesignSystem.Spacing.sm) {
                    AvatarView(
                        emoji: userEmoji ?? "👤",
                        size: .medium,
                        showStatus: false
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(userName ?? "Unknown")
                            .font(DesignSystem.Typography.headline())

                        HStack(spacing: 4) {
                            Text("Voice")
                                .font(DesignSystem.Typography.caption1(.medium))
                                .foregroundColor(DesignSystem.Colors.warning)

                            Text("•")
                                .font(DesignSystem.Typography.caption2())
                                .foregroundColor(DesignSystem.Colors.tertiaryLabel)

                            Text(message.timeAgo)
                                .font(DesignSystem.Typography.caption1())
                                .foregroundColor(DesignSystem.Colors.secondaryLabel)
                        }
                    }

                    Spacer()

                    // Upload status or duration
                    if message.uploadStatus == .completed {
                        Text(message.formattedDuration)
                            .font(DesignSystem.Typography.caption1(.semibold))
                            .foregroundColor(DesignSystem.Colors.secondaryLabel)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(DesignSystem.Colors.tertiaryBackground)
                            .cornerRadius(DesignSystem.CornerRadius.small)
                    } else {
                        Image(systemName: message.uploadStatus.icon)
                            .font(.system(size: DesignSystem.IconSize.medium))
                            .foregroundColor(uploadStatusColor)
                    }
                }

                // Waveform + Playback controls
                VoiceMessagePlayer(message: message)
                    .padding(.top, 4)

                // Transcript (if available and showing)
                if let transcript = message.transcript, !transcript.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            withAnimation(DesignSystem.Animation.spring) {
                                showTranscript.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "text.quote")
                                    .font(.system(size: DesignSystem.IconSize.small))

                                Text(showTranscript ? "Hide transcript" : "Show transcript")
                                    .font(DesignSystem.Typography.caption1(.medium))

                                Image(systemName: showTranscript ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(DesignSystem.Colors.primary)
                        }

                        if showTranscript {
                            Text(transcript)
                                .font(DesignSystem.Typography.callout())
                                .foregroundColor(DesignSystem.Colors.secondaryLabel)
                                .padding(DesignSystem.Spacing.sm)
                                .background(DesignSystem.Colors.tertiaryBackground)
                                .cornerRadius(DesignSystem.CornerRadius.small)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                        }
                    }
                    .padding(.top, 8)
                }

                // Recipients (for small group PTT)
                if !message.recipientIDs.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: DesignSystem.IconSize.small))
                            .foregroundColor(DesignSystem.Colors.tertiaryLabel)

                        Text("Sent to \(message.recipientIDs.count) \(message.recipientIDs.count == 1 ? "person" : "people")")
                            .font(DesignSystem.Typography.caption2())
                            .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private var uploadStatusColor: Color {
        switch message.uploadStatus {
        case .pending, .uploading:
            return DesignSystem.Colors.warning
        case .completed:
            return DesignSystem.Colors.success
        case .failed:
            return DesignSystem.Colors.error
        }
    }
}

// MARK: - Voice Message Player

struct VoiceMessagePlayer: View {
    let message: VoiceMessageModel

    @StateObject private var playbackManager = AudioPlaybackManager.shared
    @State private var isHovering = false

    var isPlaying: Bool {
        playbackManager.currentlyPlayingID == message.id && playbackManager.isPlaying
    }

    var playbackProgress: Double {
        if playbackManager.currentlyPlayingID == message.id {
            return playbackManager.playbackProgress
        }
        return 0
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Play/Pause button
            Button {
                togglePlayback()
            } label: {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.warning)
                        .frame(width: 48, height: 48)

                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: DesignSystem.IconSize.medium))
                        .foregroundColor(.white)
                        .offset(x: isPlaying ? 0 : 2) // Slight offset for play icon to look centered
                }
            }
            .disabled(!message.canPlay)
            .opacity(message.canPlay ? 1.0 : 0.5)

            // Waveform visualization
            VStack(spacing: 4) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 2)
                            .fill(DesignSystem.Colors.tertiaryBackground)
                            .frame(height: 4)

                        // Progress
                        RoundedRectangle(cornerRadius: 2)
                            .fill(DesignSystem.Colors.warning)
                            .frame(width: geometry.size.width * playbackProgress, height: 4)
                    }
                }
                .frame(height: 4)

                // Time labels
                HStack {
                    Text(currentTimeText)
                        .font(DesignSystem.Typography.caption2(.medium))
                        .foregroundColor(DesignSystem.Colors.secondaryLabel)

                    Spacer()

                    Text(message.formattedDuration)
                        .font(DesignSystem.Typography.caption2())
                        .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                }
            }
        }
        .padding(DesignSystem.Spacing.xs)
        .background(DesignSystem.Colors.tertiaryBackground.opacity(0.3))
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }

    private var currentTimeText: String {
        if playbackManager.currentlyPlayingID == message.id {
            let minutes = Int(playbackManager.currentTime) / 60
            let seconds = Int(playbackManager.currentTime) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
        return "0:00"
    }

    private func togglePlayback() {
        guard let url = message.fileURL else { return }

        Task {
            do {
                HapticManager.shared.impact(.medium)
                try await playbackManager.togglePlayPause(id: message.id, url: url)
            } catch {
                print("Playback failed: \(error)")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        VoiceMessageCard(
            message: VoiceMessageModel(
                groupID: UUID(),
                senderID: UUID(),
                recipientIDs: [],
                duration: 45,
                transcript: "Hey everyone, just wanted to let you know that I'll be running about 15 minutes late to dinner tonight. See you soon!",
                uploadStatus: .completed
            ),
            userName: "Mom",
            userEmoji: "👩"
        )

        VoiceMessageCard(
            message: VoiceMessageModel(
                groupID: UUID(),
                senderID: UUID(),
                recipientIDs: [UUID(), UUID(), UUID()],
                duration: 12,
                transcript: "Quick update from the game!",
                uploadStatus: .completed
            ),
            userName: "Dad",
            userEmoji: "👨"
        )

        VoiceMessageCard(
            message: VoiceMessageModel(
                groupID: UUID(),
                senderID: UUID(),
                recipientIDs: [],
                duration: 30,
                uploadStatus: .uploading,
                uploadProgress: 0.6
            ),
            userName: "Sister",
            userEmoji: "👧"
        )
    }
    .padding()
}
