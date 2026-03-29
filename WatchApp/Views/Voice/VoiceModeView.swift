import SwiftUI

struct VoiceModeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var transcribedText = ""
    @State private var isListening = false
    @State private var waveformLevels: [CGFloat] = Array(repeating: 0.3, count: 7)
    @State private var animationTimer: Timer?
    @State private var pulseScale: CGFloat = 1.0

    let onTextReceived: (String) -> Void

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Spacer()

            // Waveform
            if isListening {
                HStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(DesignTokens.Colors.chatGPTGreen)
                            .frame(width: 4, height: waveformLevels[index] * 35)
                            .animation(.easeInOut(duration: 0.12), value: waveformLevels[index])
                    }
                }
                .frame(height: 40)
            } else {
                Image(systemName: "waveform")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
                    .frame(height: 40)
            }

            Text(isListening ? "Listening..." : "Tap to speak")
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundStyle(isListening ? DesignTokens.Colors.chatGPTGreen : .secondary)

            // Mic button
            Button {
                if isListening { stopListening() } else { startListening() }
            } label: {
                ZStack {
                    if isListening {
                        Circle()
                            .stroke(DesignTokens.Colors.chatGPTGreen.opacity(0.2), lineWidth: 2)
                            .frame(width: 74, height: 74)
                            .scaleEffect(pulseScale)
                            .opacity(2.0 - Double(pulseScale))
                    }

                    Image(systemName: isListening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(isListening ? .white : DesignTokens.Colors.chatGPTGreen)
                        .frame(width: 60, height: 60)
                        .glassEffect(
                            isListening
                                ? .regular.tint(DesignTokens.Colors.chatGPTGreen)
                                : .regular,
                            in: .circle
                        )
                }
            }
            .buttonStyle(.plain)

            if !transcribedText.isEmpty {
                Text(transcribedText)
                    .font(DesignTokens.Typography.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Spacing.md)
            }

            Spacer()

            if !transcribedText.isEmpty && !isListening {
                Button {
                    onTextReceived(transcribedText)
                    dismiss()
                } label: {
                    Label("Send", systemImage: "arrow.up")
                        .font(DesignTokens.Typography.bodyMedium)
                }
                .buttonStyle(.glassProminent)
                .tint(DesignTokens.Colors.chatGPTGreen)
            }
        }
        .padding()
        .onDisappear { stopWaveformAnimation() }
    }

    private func startListening() {
        withAnimation(DesignTokens.Animation.spring) { isListening = true }
        transcribedText = ""
        startWaveformAnimation()
        startPulse()
        HapticManager.shared.play(.tap)
    }

    private func stopListening() {
        withAnimation(DesignTokens.Animation.spring) { isListening = false }
        stopWaveformAnimation()
        HapticManager.shared.play(.tap)
    }

    private func startWaveformAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { _ in
            for i in 0..<waveformLevels.count {
                waveformLevels[i] = CGFloat.random(in: 0.15...1.0)
            }
        }
    }

    private func stopWaveformAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        withAnimation(.easeOut(duration: 0.3)) {
            waveformLevels = Array(repeating: 0.3, count: 7)
        }
    }

    private func startPulse() {
        withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
            pulseScale = 1.5
        }
    }
}
