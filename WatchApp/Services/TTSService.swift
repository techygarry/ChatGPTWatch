import Foundation
import AVFoundation
import Observation

@Observable
@MainActor
final class TTSService {
    var isSpeaking = false
    private var audioPlayer: AVAudioPlayer?
    private var currentTask: Task<Void, Never>?

    private var apiKey: String {
        KeychainService.shared.load(key: KeychainKeys.openAIAPIKey) ?? ""
    }

    func speak(_ text: String, voice: String = "alloy") {
        stop()
        guard !text.isEmpty, !apiKey.isEmpty else { return }
        isSpeaking = true

        currentTask = Task {
            do {
                let url = URL(string: "\(AppConstants.openAIBaseURL)/audio/speech")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.timeoutInterval = 30

                // Truncate long text for watch (keep under ~500 chars)
                let truncated = text.count > 500 ? String(text.prefix(500)) : text

                let body: [String: Any] = [
                    "model": "tts-1",
                    "input": truncated,
                    "voice": voice,
                    "response_format": "mp3",
                    "speed": 1.0
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)

                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    await MainActor.run { isSpeaking = false }
                    return
                }

                if Task.isCancelled { return }

                // Configure audio session
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default)
                try session.setActive(true)

                let player = try AVAudioPlayer(data: data)
                self.audioPlayer = player
                player.play()

                // Wait for playback to finish
                while player.isPlaying && !Task.isCancelled {
                    try await Task.sleep(for: .milliseconds(200))
                }

                await MainActor.run { isSpeaking = false }
            } catch {
                await MainActor.run { isSpeaking = false }
            }
        }
    }

    func stop() {
        currentTask?.cancel()
        currentTask = nil
        audioPlayer?.stop()
        audioPlayer = nil
        isSpeaking = false
    }
}
