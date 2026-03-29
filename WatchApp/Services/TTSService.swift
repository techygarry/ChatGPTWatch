import Foundation
import AVFoundation
import Observation

@Observable
@MainActor
final class TTSService: NSObject {
    var isSpeaking = false
    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private var currentTask: Task<Void, Never>?

    private var apiKey: String {
        KeychainService.shared.load(key: KeychainKeys.openAIAPIKey) ?? ""
    }

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Primary: System voice (works offline, instant)

    func speak(_ text: String) {
        stop()
        guard !text.isEmpty else { return }
        isSpeaking = true

        // Try OpenAI TTS first, fall back to system voice
        if !apiKey.isEmpty {
            speakWithOpenAI(text)
        } else {
            speakWithSystem(text)
        }
    }

    private func speakWithSystem(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .voicePrompt)
            try session.setActive(true)
        } catch {
            // Continue anyway
        }

        synthesizer.speak(utterance)
    }

    // MARK: - Premium: OpenAI TTS (natural voice)

    private func speakWithOpenAI(_ text: String) {
        currentTask = Task {
            do {
                let url = URL(string: "\(AppConstants.openAIBaseURL)/audio/speech")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.timeoutInterval = 15

                let truncated = text.count > 500 ? String(text.prefix(500)) : text
                let body: [String: Any] = [
                    "model": "tts-1",
                    "input": truncated,
                    "voice": "alloy",
                    "response_format": "aac",
                    "speed": 1.0
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)

                let (data, response) = try await URLSession.shared.data(for: request)

                if Task.isCancelled { return }

                guard let http = response as? HTTPURLResponse, http.statusCode == 200, data.count > 100 else {
                    // API failed — fall back to system voice
                    await MainActor.run { speakWithSystem(truncated) }
                    return
                }

                // Play audio
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .voicePrompt)
                try session.setActive(true)

                let player = try AVAudioPlayer(data: data)
                self.audioPlayer = player
                player.prepareToPlay()
                player.play()

                // Wait for playback
                while player.isPlaying && !Task.isCancelled {
                    try await Task.sleep(for: .milliseconds(200))
                }

                await MainActor.run {
                    isSpeaking = false
                    try? AVAudioSession.sharedInstance().setActive(false)
                }
            } catch {
                // Network/decode error — fall back to system voice
                let fallbackText = text.count > 500 ? String(text.prefix(500)) : text
                await MainActor.run { speakWithSystem(fallbackText) }
            }
        }
    }

    // MARK: - Stop

    func stop() {
        currentTask?.cancel()
        currentTask = nil

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        audioPlayer?.stop()
        audioPlayer = nil
        isSpeaking = false

        try? AVAudioSession.sharedInstance().setActive(false)
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TTSService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
            try? AVAudioSession.sharedInstance().setActive(false)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
        }
    }
}
