import Foundation
import SwiftData

// MARK: - Persisted Conversation
@Model
final class SDConversation {
    @Attribute(.unique) var id: UUID
    var title: String
    var model: String
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \SDMessage.conversation)
    var messages: [SDMessage]

    init(id: UUID = UUID(), title: String = "New Chat", model: String = "gpt-5.4", createdAt: Date = Date(), updatedAt: Date = Date(), messages: [SDMessage] = []) {
        self.id = id
        self.title = title
        self.model = model
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = messages
    }

    func toConversation() -> Conversation {
        Conversation(
            id: id,
            title: title,
            messages: messages.sorted { $0.timestamp < $1.timestamp }.map { $0.toChatMessage() },
            model: model,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Persisted Message
@Model
final class SDMessage {
    @Attribute(.unique) var id: UUID
    var roleRaw: String
    var content: String
    var timestamp: Date
    var conversation: SDConversation?

    init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date()) {
        self.id = id
        self.roleRaw = role.rawValue
        self.content = content
        self.timestamp = timestamp
    }

    var role: MessageRole {
        MessageRole(rawValue: roleRaw) ?? .user
    }

    func toChatMessage() -> ChatMessage {
        ChatMessage(id: id, role: role, content: content, timestamp: timestamp)
    }
}

// MARK: - Persisted Codex Session
@Model
final class SDCodexSession {
    @Attribute(.unique) var sessionId: String
    var statusRaw: String
    var instructions: String
    var input: String
    var outputJSON: String
    var filesChangedJSON: String
    var model: String
    var createdAt: Date

    init(session: CodexSession) {
        self.sessionId = session.id
        self.statusRaw = session.status.rawValue
        self.instructions = session.instructions
        self.input = session.input
        self.outputJSON = (try? String(data: JSONEncoder().encode(session.output), encoding: .utf8)) ?? "[]"
        self.filesChangedJSON = (try? String(data: JSONEncoder().encode(session.filesChanged), encoding: .utf8)) ?? "[]"
        self.model = session.model
        self.createdAt = session.createdAt
    }

    func toCodexSession() -> CodexSession {
        let output = (try? JSONDecoder().decode([CodexOutputItem].self, from: Data(outputJSON.utf8))) ?? []
        let files = (try? JSONDecoder().decode([CodexFileChange].self, from: Data(filesChangedJSON.utf8))) ?? []
        return CodexSession(
            id: sessionId,
            status: CodexStatus(rawValue: statusRaw) ?? .queued,
            instructions: instructions,
            input: input,
            output: output,
            filesChanged: files,
            createdAt: createdAt,
            model: model
        )
    }
}
