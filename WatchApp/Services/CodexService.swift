import Foundation
import Observation

@Observable
final class CodexService: @unchecked Sendable {

    var apiKey: String {
        KeychainService.shared.load(key: KeychainKeys.openAIAPIKey) ?? ""
    }
    var hasAPIKey: Bool { !apiKey.isEmpty }

    // Relay server config — local Mac or via Cloudflare tunnel
    private let relayToken = "chatgpt-watch-relay-2026"

    var relayURL: String {
        // Check for custom URL (set via companion app or settings)
        if let custom = UserDefaults(suiteName: AppGroupConstants.suiteName)?.string(forKey: "codexRelayURL"), !custom.isEmpty {
            return custom
        }
        // Default: local Mac relay
        return "https://limited-claims-grateful-allan.trycloudflare.com"
    }

    // MARK: - Create Task on Mac via Relay
    func createSession(input: String, instructions: String? = nil, model: String = CodexModel.gpt5_3Codex.rawValue, workingDir: String? = nil) async throws -> CodexSession {
        let url = URL(string: "\(relayURL)/tasks")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(relayToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        var body: [String: Any] = [
            "prompt": input,
            "model": model
        ]
        if let workingDir { body["workingDir"] = workingDir }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTP(response)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = json["id"] as? String else {
            throw APIError.decodingFailed("Invalid relay response")
        }

        return CodexSession(
            id: id,
            status: .inProgress,
            instructions: instructions ?? "",
            input: input,
            model: model
        )
    }

    // MARK: - List Tasks from Relay
    func listSessions() async throws -> [CodexSession] {
        let url = URL(string: "\(relayURL)/tasks")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(relayToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTP(response)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["tasks"] as? [[String: Any]] else {
            return []
        }

        return items.compactMap { parseRelayTask($0) }
    }

    // MARK: - Get Task Detail
    func getSession(id: String) async throws -> CodexSession {
        let url = URL(string: "\(relayURL)/tasks/\(id)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(relayToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTP(response)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.decodingFailed("Invalid response")
        }

        guard let session = parseRelayTask(json) else {
            throw APIError.decodingFailed("Could not parse task")
        }
        return session
    }

    // MARK: - Cancel Task
    func cancelSession(id: String) async throws {
        let url = URL(string: "\(relayURL)/tasks/\(id)/cancel")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(relayToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        let (_, response) = try await URLSession.shared.data(for: request)
        try validateHTTP(response)
    }

    // MARK: - Health Check
    func checkRelayHealth() async -> Bool {
        guard let url = URL(string: "\(relayURL)/health") else { return false }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(relayToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 5

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    // MARK: - Helpers
    private func validateHTTP(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError("No response from relay server")
        }
        switch http.statusCode {
        case 200...299: return
        case 401: throw APIError.invalidAPIKey
        case 404: throw APIError.networkError("Relay: task not found")
        default: throw APIError.serverError(http.statusCode, "Relay server error")
        }
    }

    private func parseRelayTask(_ dict: [String: Any]) -> CodexSession? {
        guard let id = dict["id"] as? String else { return nil }

        let statusStr = dict["status"] as? String ?? "running"
        let status: CodexStatus = switch statusStr {
        case "completed": .completed
        case "failed": .failed
        case "cancelled": .cancelled
        case "running": .inProgress
        default: .inProgress
        }

        let prompt = dict["prompt"] as? String ?? ""
        let output = dict["output"] as? String ?? ""
        let model = dict["model"] as? String ?? CodexModel.gpt5_3Codex.rawValue
        let error = dict["error"] as? String

        // Parse output into items
        var outputItems = parseCodeBlocks(output)
        if let error, !error.isEmpty {
            outputItems.append(CodexOutputItem(type: .message, content: "Error: \(error)"))
        }

        // Parse file changes from relay
        var fileChanges: [CodexFileChange] = []
        if let files = dict["filesChanged"] as? [[String: Any]] {
            for f in files {
                if let path = f["path"] as? String, let actionStr = f["action"] as? String {
                    let action = FileAction(rawValue: actionStr) ?? .modified
                    fileChanges.append(CodexFileChange(path: path, action: action))
                }
            }
        }

        var createdAt = Date()
        if let dateStr = dict["createdAt"] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            createdAt = formatter.date(from: dateStr) ?? Date()
        }

        return CodexSession(
            id: id,
            status: status,
            instructions: "",
            input: prompt,
            output: outputItems,
            filesChanged: fileChanges,
            createdAt: createdAt,
            model: model
        )
    }

    private func parseCodeBlocks(_ content: String) -> [CodexOutputItem] {
        guard !content.isEmpty else { return [] }
        var items: [CodexOutputItem] = []
        let lines = content.components(separatedBy: "\n")
        var currentCode = ""
        var inCodeBlock = false
        var textBuffer = ""

        for line in lines {
            if line.hasPrefix("```") {
                if inCodeBlock {
                    items.append(CodexOutputItem(type: .code, content: currentCode.trimmingCharacters(in: .whitespacesAndNewlines)))
                    currentCode = ""
                    inCodeBlock = false
                } else {
                    let trimmed = textBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty { items.append(CodexOutputItem(type: .message, content: trimmed)) }
                    textBuffer = ""
                    inCodeBlock = true
                }
            } else if inCodeBlock {
                currentCode += line + "\n"
            } else {
                textBuffer += line + "\n"
            }
        }
        let trimmed = textBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { items.append(CodexOutputItem(type: .message, content: trimmed)) }
        if inCodeBlock && !currentCode.isEmpty {
            items.append(CodexOutputItem(type: .code, content: currentCode.trimmingCharacters(in: .whitespacesAndNewlines)))
        }
        return items.isEmpty ? [CodexOutputItem(type: .message, content: content)] : items
    }
}
