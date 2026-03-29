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
                            .fill(DesignTokens.Gradients.greenAccent)
                            .frame(width: 4, height: waveformLevels[index] * 35)
                            .animation(.easeInOut(duration: 0.12), value: waveformLevels[index])
                    }
                }
                .frame(height: 40)
                .shadow(color: DesignTokens.Colors.chatGPTGreen.opacity(0.3), radius: 8)
            } else {
                Image(systemName: "waveform")
                    .font(.title2)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                    .frame(height: 40)
            }

            // Status
            Text(isListening ? "Listening..." : "Tap to speak")
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundStyle(isListening ? DesignTokens.Colors.chatGPTGreen : DesignTokens.Colors.textSecondary)
                .animation(DesignTokens.Animation.quick, value: isListening)

            // Mic Button
            Button {
                if isListening {
                    stopListening()
                } else {
                    startListening()
                }
            } label: {
                ZStack {
                    // Outer pulse ring
                    if isListening {
                        Circle()
                            .stroke(DesignTokens.Colors.chatGPTGreen.opacity(0.15), lineWidth: 2)
                            .frame(width: 76, height: 76)
                            .scaleEffect(pulseScale)
                            .opacity(2.0 - Double(pulseScale))
                    }

                    // Main circle
                    Circle()
                        .fill(
                            isListening
                                ? AnyShapeStyle(DesignTokens.Gradients.greenAccent)
                                : AnyShapeStyle(DesignTokens.Colors.surfaceMid)
                        )
                        .frame(width: 62, height: 62)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isListening
                                        ? DesignTokens.Colors.chatGPTGreenLight.opacity(0.3)
                                        : DesignTokens.Colors.glassStroke,
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: isListening ? DesignTokens.Colors.chatGPTGreen.opacity(0.4) : .clear, radius: 12)

                    Image(systemName: isListening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(isListening ? .white : DesignTokens.Colors.chatGPTGreen)
                }
            }
            .buttonStyle(.plain)

            // Transcribed text
            if !transcribedText.isEmpty {
                Text(transcribedText)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }

            Spacer()

            // Send
            if !transcribedText.isEmpty && !isListening {
                Button {
                    onTextReceived(transcribedText)
                    dismiss()
                } label: {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 10, weight: .bold))
                        Text("Send")
                            .font(DesignTokens.Typography.bodyMedium)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignTokens.Colors.chatGPTGreen)
                .accentGlow(color: DesignTokens.Colors.chatGPTGreen)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding()
        .background(DesignTokens.Colors.surfaceDark)
        .onDisappear {
            stopWaveformAnimation()
        }
    }

    private func startListening() {
        withAnimation(DesignTokens.Animation.spring) {
            isListening = true
        }
        transcribedText = ""
        startWaveformAnimation()
        startPulse()
        HapticManager.shared.play(.tap)
    }

    private func stopListening() {
        withAnimation(DesignTokens.Animation.spring) {
            isListening = false
        }
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
