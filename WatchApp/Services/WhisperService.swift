import Foundation
import AVFoundation
import Observation

@Observable
@MainActor
final class WhisperService: NSObject {
    var isRecording = false
    var isTranscribing = false
    var errorMessage: String?

    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("voice_input.m4a")
    }

    private var apiKey: String {
        KeychainService.shared.load(key: KeychainKeys.openAIAPIKey) ?? ""
    }

    // MARK: - Record

    func startRecording() {
        errorMessage = nil

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement)
            try session.setActive(true)

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            // Remove old recording
            try? FileManager.default.removeItem(at: recordingURL)

            let recorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            recorder.delegate = self
            recorder.record()
            self.audioRecorder = recorder
            isRecording = true
        } catch {
            errorMessage = "Mic access failed"
            isRecording = false
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    // MARK: - Transcribe with Whisper

    func transcribe() async -> String? {
        guard FileManager.default.fileExists(atPath: recordingURL.path),
              !apiKey.isEmpty else {
            errorMessage = "No recording or API key"
            return nil
        }

        isTranscribing = true
        defer { isTranscribing = false }

        do {
            let audioData = try Data(contentsOf: recordingURL)
            guard audioData.count > 1000 else {
                errorMessage = "Recording too short"
                return nil
            }

            let boundary = UUID().uuidString
            let url = URL(string: "\(AppConstants.openAIBaseURL)/audio/transcriptions")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 15

            var body = Data()
            // Model field
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
            body.append("whisper-1\r\n".data(using: .utf8)!)
            // Audio file
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
            body.append(audioData)
            body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

            request.httpBody = body

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                errorMessage = "Whisper API error"
                return nil
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let text = json["text"] as? String, !text.trimmed.isEmpty {
                return text.trimmed
            }

            errorMessage = "No speech detected"
            return nil
        } catch {
            errorMessage = "Transcription failed"
            return nil
        }
    }
}

extension WhisperService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            isRecording = false
        }
    }
}
