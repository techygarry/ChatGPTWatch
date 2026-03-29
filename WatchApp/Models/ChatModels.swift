import Foundation

// MARK: - Message Role
enum MessageRole: String, Codable, Sendable, CaseIterable {
    case system
    case user
    case assistant
}

// MARK: - Chat Message
struct ChatMessage: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let role: MessageRole
    var content: String
    let timestamp: Date
    var isStreaming: Bool

    init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date(), isStreaming: Bool = false) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isStreaming = isStreaming
    }
}

// MARK: - Conversation
struct Conversation: Identifiable, Sendable, Equatable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    var model: String
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), title: String = "New Chat", messages: [ChatMessage] = [], model: String = GPTModel.gpt5_4.rawValue, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.messages = messages
        self.model = model
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - GPT Models
enum GPTModel: String, CaseIterable, Sendable, Identifiable {
    // GPT-5.4 family (latest, March 2026)
    case gpt5_4Pro = "gpt-5.4-pro"
    case gpt5_4 = "gpt-5.4"
    case gpt5_4Mini = "gpt-5.4-mini"
    case gpt5_4Nano = "gpt-5.4-nano"
    // GPT-5.3
    case gpt5_3 = "gpt-5.3-chat-latest"
    // GPT-5.2
    case gpt5_2Pro = "gpt-5.2-pro"
    case gpt5_2 = "gpt-5.2"
    // GPT-5
    case gpt5Pro = "gpt-5-pro"
    case gpt5 = "gpt-5"
    case gpt5Mini = "gpt-5-mini"
    case gpt5Nano = "gpt-5-nano"
    // Reasoning
    case o3 = "o3"
    case o4Mini = "o4-mini"
    case o1Pro = "o1-pro"
    // Legacy
    case gpt4_1 = "gpt-4.1"
    case gpt4o = "gpt-4o"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gpt5_4Pro: "GPT-5.4 Pro"
        case .gpt5_4: "GPT-5.4"
        case .gpt5_4Mini: "GPT-5.4 mini"
        case .gpt5_4Nano: "GPT-5.4 nano"
        case .gpt5_3: "GPT-5.3"
        case .gpt5_2Pro: "GPT-5.2 Pro"
        case .gpt5_2: "GPT-5.2"
        case .gpt5Pro: "GPT-5 Pro"
        case .gpt5: "GPT-5"
        case .gpt5Mini: "GPT-5 mini"
        case .gpt5Nano: "GPT-5 nano"
        case .o3: "o3"
        case .o4Mini: "o4-mini"
        case .o1Pro: "o1-pro"
        case .gpt4_1: "GPT-4.1"
        case .gpt4o: "GPT-4o"
        }
    }

    var supportsStreaming: Bool { true }
}

// MARK: - Streaming
struct StreamChunk: Sendable {
    let delta: String?
    let isComplete: Bool
    let error: APIError?

    init(delta: String? = nil, isComplete: Bool = false, error: APIError? = nil) {
        self.delta = delta
        self.isComplete = isComplete
        self.error = error
    }
}

// MARK: - API Error
enum APIError: Error, LocalizedError, Sendable {
    case invalidAPIKey
    case rateLimited
    case networkError(String)
    case streamingFailed(String)
    case serverError(Int, String)
    case decodingFailed(String)
    case cancelled
    case noAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey: "Invalid API key"
        case .rateLimited: "Rate limited — try again shortly"
        case .networkError(let msg): "Network error: \(msg)"
        case .streamingFailed(let msg): "Streaming failed: \(msg)"
        case .serverError(let code, let msg): "Server error \(code): \(msg)"
        case .decodingFailed(let msg): "Decoding error: \(msg)"
        case .cancelled: "Request cancelled"
        case .noAPIKey: "No API key configured"
        }
    }
}
