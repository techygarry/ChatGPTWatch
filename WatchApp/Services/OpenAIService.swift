import Foundation
import Observation

@Observable
final class OpenAIService: @unchecked Sendable {
    private var currentTask: Task<Void, Never>?

    var apiKey: String {
        get { KeychainService.shared.load(key: KeychainKeys.openAIAPIKey) ?? "" }
        set { KeychainService.shared.save(key: KeychainKeys.openAIAPIKey, value: newValue) }
    }

    var hasAPIKey: Bool { !apiKey.isEmpty }

    func chat(messages: [(role: String, content: String)], model: String, stream: Bool = true) -> AsyncThrowingStream<StreamChunk, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard hasAPIKey else {
                        continuation.yield(StreamChunk(error: .noAPIKey))
                        continuation.finish()
                        return
                    }

                    let url = URL(string: "\(AppConstants.openAIBaseURL)/chat/completions")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.timeoutInterval = 120

                    let body: [String: Any] = [
                        "model": model,
                        "messages": messages.map { ["role": $0.role, "content": $0.content] },
                        "stream": stream,
                        "max_completion_tokens": 2048
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    if stream {
                        let (bytes, response) = try await URLSession.shared.bytes(for: request)

                        guard let httpResponse = response as? HTTPURLResponse else {
                            continuation.yield(StreamChunk(error: .networkError("Invalid response")))
                            continuation.finish()
                            return
                        }

                        if httpResponse.statusCode == 401 {
                            continuation.yield(StreamChunk(error: .invalidAPIKey))
                            continuation.finish()
                            return
                        }

                        if httpResponse.statusCode == 429 {
                            continuation.yield(StreamChunk(error: .rateLimited))
                            continuation.finish()
                            return
                        }

                        if httpResponse.statusCode != 200 {
                            continuation.yield(StreamChunk(error: .serverError(httpResponse.statusCode, "Server error")))
                            continuation.finish()
                            return
                        }

                        for try await line in bytes.lines {
                            if Task.isCancelled { break }

                            guard line.hasPrefix("data: ") else { continue }
                            let data = String(line.dropFirst(6))

                            if data == "[DONE]" {
                                continuation.yield(StreamChunk(isComplete: true))
                                break
                            }

                            guard let jsonData = data.data(using: .utf8),
                                  let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                  let choices = json["choices"] as? [[String: Any]],
                                  let firstChoice = choices.first,
                                  let delta = firstChoice["delta"] as? [String: Any] else { continue }

                            if let content = delta["content"] as? String {
                                continuation.yield(StreamChunk(delta: content))
                            }
                        }
                    } else {
                        let (data, response) = try await URLSession.shared.data(for: request)

                        guard let httpResponse = response as? HTTPURLResponse else {
                            continuation.yield(StreamChunk(error: .networkError("Invalid response")))
                            continuation.finish()
                            return
                        }

                        if httpResponse.statusCode == 401 {
                            continuation.yield(StreamChunk(error: .invalidAPIKey))
                            continuation.finish()
                            return
                        }

                        if httpResponse.statusCode != 200 {
                            continuation.yield(StreamChunk(error: .serverError(httpResponse.statusCode, "Server error")))
                            continuation.finish()
                            return
                        }

                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let choices = json["choices"] as? [[String: Any]],
                           let firstChoice = choices.first,
                           let message = firstChoice["message"] as? [String: Any],
                           let content = message["content"] as? String {
                            continuation.yield(StreamChunk(delta: content))
                        }

                        continuation.yield(StreamChunk(isComplete: true))
                    }

                    continuation.finish()
                } catch is CancellationError {
                    continuation.yield(StreamChunk(error: .cancelled))
                    continuation.finish()
                } catch {
                    continuation.yield(StreamChunk(error: .networkError(error.localizedDescription)))
                    continuation.finish()
                }
            }
            self.currentTask = task
            continuation.onTermination = { @Sendable _ in task.cancel() }
        }
    }

    func cancelStream() {
        currentTask?.cancel()
        currentTask = nil
    }
}
