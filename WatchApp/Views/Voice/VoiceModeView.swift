import SwiftUI

/// Live voice mode: Record → Whisper transcribe → ChatGPT → TTS speak → repeat
struct VoiceModeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var phase: VoicePhase = .idle
    @State private var transcribedText = ""
    @State private var responseText = ""
    @State private var waveformLevels: [CGFloat] = Array(repeating: 0.3, count: 7)
    @State private var waveformTimer: Timer?
    @State private var pulseScale: CGFloat = 1.0

    let onTextReceived: (String) -> Void

    enum VoicePhase {
        case idle, recording, transcribing, thinking, speaking
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Spacer()

            // Visual indicator
            ZStack {
                // Pulse ring
                if phase == .recording || phase == .speaking {
                    Circle()
                        .stroke(phaseColor.opacity(0.2), lineWidth: 2)
                        .frame(width: 90, height: 90)
                        .scaleEffect(pulseScale)
                        .opacity(2.0 - Double(pulseScale))
                }

                // Waveform ring
                if phase == .recording {
                    HStack(spacing: 3) {
                        ForEach(0..<7, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(DesignTokens.Colors.chatGPTGreen)
                                .frame(width: 3, height: waveformLevels[index] * 30)
                                .animation(.easeInOut(duration: 0.1), value: waveformLevels[index])
                        }
                    }
                } else if phase == .transcribing || phase == .thinking {
                    ProgressView()
                        .tint(phaseColor)
                        .scaleEffect(1.2)
                } else if phase == .speaking {
                    Image("ChatGPTLogo")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                        .frame(width: 36, height: 36)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                }
            }
            .frame(width: 80, height: 80)

            // Status text
            Text(statusText)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(phaseColor)
                .multilineTextAlignment(.center)

            // Transcription preview
            if !transcribedText.isEmpty && phase != .idle {
                Text(transcribedText)
                    .font(DesignTokens.Typography.micro)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Action buttons
            HStack(spacing: DesignTokens.Spacing.md) {
                // Close
                Button {
                    stopEverything()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                }
                .buttonStyle(.bordered)
                .tint(.secondary)

                // Main action
                Button {
                    handleMainAction()
                } label: {
                    Image(systemName: mainButtonIcon)
                        .font(.system(size: 16))
                }
                .buttonStyle(.borderedProminent)
                .tint(phaseColor)
            }
        }
        .padding()
        .onDisappear {
            stopEverything()
        }
        .onChange(of: appState.ttsService.isSpeaking) { _, isSpeaking in
            if !isSpeaking && phase == .speaking {
                // TTS finished — go back to idle, ready for next question
                phase = .idle
                stopWaveform()
            }
        }
    }

    // MARK: - Status

    private var statusText: String {
        switch phase {
        case .idle: "Tap to speak"
        case .recording: "Listening..."
        case .transcribing: "Processing..."
        case .thinking: "Thinking..."
        case .speaking: "Speaking..."
        }
    }

    private var phaseColor: Color {
        switch phase {
        case .idle: DesignTokens.Colors.chatGPTGreen
        case .recording: DesignTokens.Colors.chatGPTGreen
        case .transcribing: DesignTokens.Colors.codexBlue
        case .thinking: DesignTokens.Colors.codexPurple
        case .speaking: DesignTokens.Colors.chatGPTGreen
        }
    }

    private var mainButtonIcon: String {
        switch phase {
        case .idle: "mic.fill"
        case .recording: "stop.fill"
        case .transcribing, .thinking: "stop.fill"
        case .speaking: "stop.fill"
        }
    }

    // MARK: - Actions

    private func handleMainAction() {
        switch phase {
        case .idle:
            startRecording()
        case .recording:
            stopAndProcess()
        case .speaking:
            appState.ttsService.stop()
            phase = .idle
            stopWaveform()
        case .transcribing, .thinking:
            stopEverything()
        }
    }

    private func startRecording() {
        transcribedText = ""
        responseText = ""
        phase = .recording
        appState.whisperService.startRecording()
        startWaveform()
        startPulse()
        HapticManager.shared.play(.tap)
    }

    private func stopAndProcess() {
        appState.whisperService.stopRecording()
        stopWaveform()
        phase = .transcribing
        HapticManager.shared.play(.tap)

        Task {
            // Step 1: Transcribe
            guard let text = await appState.whisperService.transcribe() else {
                phase = .idle
                return
            }
            transcribedText = text

            // Step 2: Send to ChatGPT
            phase = .thinking
            onTextReceived(text)

            // Step 3: Wait for response to complete, then TTS will auto-speak
            // The ChatDetailView's onReceive timer handles auto-speak via lastCompletedResponse
            phase = .speaking
            startPulse()
        }
    }

    private func stopEverything() {
        if appState.whisperService.isRecording {
            appState.whisperService.stopRecording()
        }
        appState.ttsService.stop()
        stopWaveform()
        phase = .idle
    }

    // MARK: - Waveform

    private func startWaveform() {
        waveformTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            for i in 0..<waveformLevels.count {
                waveformLevels[i] = CGFloat.random(in: 0.15...1.0)
            }
        }
    }

    private func stopWaveform() {
        waveformTimer?.invalidate()
        waveformTimer = nil
        withAnimation(.easeOut(duration: 0.3)) {
            waveformLevels = Array(repeating: 0.3, count: 7)
        }
    }

    private func startPulse() {
        pulseScale = 1.0
        withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
            pulseScale = 1.5
        }
    }
}
