import SwiftUI

// MARK: - Voice Record Sheet
// Beautiful interface for recording voice messages (walkie talkie)

struct VoiceRecordSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: PulseDataManager

    @StateObject private var captureManager = AudioCaptureManager()
    @StateObject private var playbackManager = AudioPlaybackManager.shared
    @StateObject private var uploadManager = AudioUploadManager.shared
    @StateObject private var speechManager = SpeechRecognitionManager.shared

    @State private var recordingState: RecordingState = .idle
    @State private var recordedFileURL: URL?
    @State private var selectedRecipients: Set<UUID> = []
    @State private var showRecipientPicker = false
    @State private var isTranscribing = false
    @State private var transcript: String?
    @State private var isSending = false

    enum RecordingState {
        case idle
        case recording
        case recorded
        case playing
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background with subtle gradient
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.warning.opacity(0.1),
                        DesignSystem.Colors.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: DesignSystem.Spacing.xl) {
                    Spacer()

                    // Waveform visualization
                    if recordingState == .recording {
                        LiveWaveformView(audioLevel: captureManager.audioLevel)
                            .frame(height: 100)
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Duration or status
                    statusText
                        .font(DesignSystem.Typography.title2(.semibold))
                        .foregroundColor(DesignSystem.Colors.label)

                    Spacer()

                    // Main record button
                    recordButton

                    // Playback controls (when recorded)
                    if recordingState == .recorded, let url = recordedFileURL {
                        playbackControls(url: url)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Recipient selection (when recorded)
                    if recordingState == .recorded {
                        recipientSection
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Action buttons
                    actionButtons
                        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                        .padding(.bottom, DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("Voice Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        cancelRecording()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showRecipientPicker) {
                RecipientPickerSheet(selectedRecipients: $selectedRecipients)
            }
        }
        .onAppear {
            PostHogManager.shared.screen("voice_record")
        }
    }

    // MARK: - Status Text

    @ViewBuilder
    private var statusText: some View {
        switch recordingState {
        case .idle:
            Text("Hold to record")
        case .recording:
            Text(formattedDuration(captureManager.recordingDuration))
                .monospacedDigit()
        case .recorded:
            if isTranscribing {
                Text("Transcribing...")
            } else if let transcript = transcript {
                Text("Ready to send")
            } else {
                Text("Tap to play")
            }
        case .playing:
            Text("Playing...")
        }
    }

    // MARK: - Record Button

    private var recordButton: some View {
        ZStack {
            // Pulsing ring when recording
            if recordingState == .recording {
                Circle()
                    .stroke(DesignSystem.Colors.warning.opacity(0.3), lineWidth: 4)
                    .frame(width: 140, height: 140)
                    .scaleEffect(CGFloat(captureManager.audioLevel * 0.3 + 1.0))
                    .animation(.easeInOut(duration: 0.1), value: captureManager.audioLevel)
            }

            // Main button
            Button {
                // Tap action (for recorded state)
                if recordingState == .recorded {
                    playRecording()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(buttonColor)
                        .frame(width: 120, height: 120)
                        .shadow(
                            color: buttonColor.opacity(0.4),
                            radius: 20,
                            x: 0,
                            y: 10
                        )

                    Image(systemName: buttonIcon)
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.2)
                    .onEnded { _ in
                        if recordingState == .idle {
                            startRecording()
                        }
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { _ in
                        if recordingState == .recording {
                            stopRecording()
                        }
                    }
            )
        }
    }

    private var buttonColor: Color {
        switch recordingState {
        case .idle:
            return DesignSystem.Colors.warning
        case .recording:
            return DesignSystem.Colors.error
        case .recorded, .playing:
            return DesignSystem.Colors.primary
        }
    }

    private var buttonIcon: String {
        switch recordingState {
        case .idle:
            return "mic.fill"
        case .recording:
            return "stop.fill"
        case .recorded:
            return "play.fill"
        case .playing:
            return "pause.fill"
        }
    }

    // MARK: - Playback Controls

    private func playbackControls(url: URL) -> some View {
        Card {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Play/Pause
                Button {
                    playRecording()
                } label: {
                    Image(systemName: recordingState == .playing ? "pause.fill" : "play.fill")
                        .font(.system(size: DesignSystem.IconSize.large))
                        .foregroundColor(DesignSystem.Colors.primary)
                }

                // Progress
                VStack(spacing: 4) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(DesignSystem.Colors.tertiaryBackground)
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(DesignSystem.Colors.primary)
                                .frame(width: geometry.size.width * playbackProgress, height: 4)
                        }
                    }
                    .frame(height: 4)

                    HStack {
                        Text(currentPlaybackTime)
                            .font(DesignSystem.Typography.caption2(.medium))
                            .foregroundColor(DesignSystem.Colors.secondaryLabel)

                        Spacer()

                        Text(totalDuration)
                            .font(DesignSystem.Typography.caption2())
                            .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                    }
                }

                // Delete
                Button {
                    deleteRecording()
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: DesignSystem.IconSize.large))
                        .foregroundColor(DesignSystem.Colors.error)
                }
            }
            .padding(DesignSystem.Spacing.sm)
        }
        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
    }

    private var playbackProgress: Double {
        guard playbackManager.currentlyPlayingID != nil else { return 0 }
        return playbackManager.playbackProgress
    }

    private var currentPlaybackTime: String {
        formattedDuration(playbackManager.currentTime)
    }

    private var totalDuration: String {
        formattedDuration(playbackManager.duration)
    }

    // MARK: - Recipient Section

    private var recipientSection: some View {
        Card {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Text("Send to")
                        .font(DesignSystem.Typography.headline())

                    Spacer()

                    Button {
                        showRecipientPicker = true
                    } label: {
                        Text(recipientText)
                            .font(DesignSystem.Typography.callout(.medium))
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }

                if !selectedRecipients.isEmpty {
                    Text("\(selectedRecipients.count) \(selectedRecipients.count == 1 ? "person" : "people") selected")
                        .font(DesignSystem.Typography.caption1())
                        .foregroundColor(DesignSystem.Colors.secondaryLabel)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
    }

    private var recipientText: String {
        if selectedRecipients.isEmpty {
            return "Everyone"
        } else {
            return "Change"
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        if recordingState == .recorded {
            ActionButton(
                "Send Voice Message",
                icon: "paperplane.fill",
                isLoading: isSending
            ) {
                sendVoiceMessage()
            }
        }
    }

    // MARK: - Actions

    private func startRecording() {
        Task {
            do {
                HapticManager.shared.impact(.heavy)
                let url = try await captureManager.startRecording()
                recordedFileURL = url

                withAnimation(DesignSystem.Animation.spring) {
                    recordingState = .recording
                }
            } catch {
                print("Recording failed: \(error)")
            }
        }
    }

    private func stopRecording() {
        guard let url = captureManager.stopRecording() else { return }

        HapticManager.shared.notification(.success)

        recordedFileURL = url

        withAnimation(DesignSystem.Animation.spring) {
            recordingState = .recorded
        }

        // Auto-transcribe
        transcribeRecording(url: url)
    }

    private func playRecording() {
        guard let url = recordedFileURL else { return }

        Task {
            do {
                if recordingState == .playing {
                    playbackManager.pause()
                    recordingState = .recorded
                } else {
                    try await playbackManager.play(id: UUID(), url: url)
                    recordingState = .playing
                }
            } catch {
                print("Playback failed: \(error)")
            }
        }
    }

    private func deleteRecording() {
        guard let url = recordedFileURL else { return }

        HapticManager.shared.impact(.medium)

        // Delete file
        try? FileManager.default.removeItem(at: url)

        // Reset state
        recordedFileURL = nil
        transcript = nil
        selectedRecipients.removeAll()

        withAnimation(DesignSystem.Animation.spring) {
            recordingState = .idle
        }
    }

    private func transcribeRecording(url: URL) {
        isTranscribing = true

        Task {
            do {
                let transcribedText = try await speechManager.transcribe(audioURL: url)
                transcript = transcribedText
            } catch {
                print("Transcription failed: \(error)")
                // It's okay if transcription fails, message can still be sent
            }
            isTranscribing = false
        }
    }

    private func sendVoiceMessage() {
        guard let url = recordedFileURL else { return }

        Task {
            isSending = true

            do {
                // Get duration
                let duration = captureManager.getDuration(of: url) ?? 0

                // Create voice message
                let message = VoiceMessageModel(
                    groupID: dataManager.currentGroup?.id ?? UUID(),
                    senderID: dataManager.currentUser?.id ?? UUID(),
                    recipientIDs: Array(selectedRecipients),
                    localFileURL: url.path,
                    duration: duration,
                    transcript: transcript,
                    uploadStatus: .pending
                )

                // Save to data manager (will handle upload)
                try await dataManager.sendVoiceMessage(message)

                // Success haptic
                HapticManager.shared.notification(.success)

                // Close sheet
                dismiss()
            } catch {
                // Error haptic
                HapticManager.shared.notification(.error)
                print("Send failed: \(error)")
            }

            isSending = false
        }
    }

    private func cancelRecording() {
        if recordingState == .recording {
            captureManager.cancelRecording()
        }

        if let url = recordedFileURL {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Live Waveform View

struct LiveWaveformView: View {
    let audioLevel: Float

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(0..<40, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(DesignSystem.Colors.warning)
                    .frame(width: 3, height: barHeight(for: index))
                    .animation(.easeInOut(duration: 0.1), value: audioLevel)
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        // Create wave pattern with audio level
        let baseHeight: CGFloat = 20
        let maxHeight: CGFloat = 80

        let wave = sin(Double(index) * 0.3) * Double(audioLevel)
        let height = baseHeight + (maxHeight - baseHeight) * CGFloat(abs(wave))

        return max(baseHeight, height)
    }
}

// MARK: - Recipient Picker Sheet

struct RecipientPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: PulseDataManager
    @Binding var selectedRecipients: Set<UUID>

    var body: some View {
        NavigationStack {
            List {
                Section {
                    // TODO: Show group members when we have member management
                    // For now, show placeholder
                    Text("All group members")
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(DesignSystem.Colors.secondaryLabel)
                } header: {
                    Text("Send to specific people (up to 5)")
                }

                Section {
                    Text("Coming soon: Select specific group members for your voice message")
                        .font(DesignSystem.Typography.callout())
                        .foregroundColor(DesignSystem.Colors.tertiaryLabel)
                }
            }
            .navigationTitle("Recipients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VoiceRecordSheet()
        .environmentObject(PulseDataManager.shared)
}
