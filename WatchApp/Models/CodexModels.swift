import Foundation

// MARK: - Codex Status
enum CodexStatus: String, Codable, Sendable {
    case queued
    case inProgress = "in_progress"
    case completed
    case failed
    case cancelled

    var displayName: String {
        switch self {
        case .queued: "Queued"
        case .inProgress: "Running"
        case .completed: "Completed"
        case .failed: "Failed"
        case .cancelled: "Cancelled"
        }
    }

    var emoji: String {
        switch self {
        case .queued: "⏳"
        case .inProgress: "🔄"
        case .completed: "✅"
        case .failed: "❌"
        case .cancelled: "⏹"
        }
    }

    var isTerminal: Bool {
        switch self {
        case .completed, .failed, .cancelled: true
        case .queued, .inProgress: false
        }
    }
}

// MARK: - Codex Session
struct CodexSession: Identifiable, Sendable, Equatable {
    let id: String
    var status: CodexStatus
    var instructions: String
    var input: String
    var output: [CodexOutputItem]
    var filesChanged: [CodexFileChange]
    var createdAt: Date
    var model: String

    init(id: String, status: CodexStatus = .queued, instructions: String = "", input: String, output: [CodexOutputItem] = [], filesChanged: [CodexFileChange] = [], createdAt: Date = Date(), model: String = CodexModel.gpt5_3Codex.rawValue) {
        self.id = id
        self.status = status
        self.instructions = instructions
        self.input = input
        self.output = output
        self.filesChanged = filesChanged
        self.createdAt = createdAt
        self.model = model
    }
}

// MARK: - Codex Output Item
struct CodexOutputItem: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let type: OutputType
    let content: String

    enum OutputType: String, Codable, Sendable {
        case message
        case code
        case fileChange = "file_change"
    }

    init(id: UUID = UUID(), type: OutputType, content: String) {
        self.id = id
        self.type = type
        self.content = content
    }
}

// MARK: - File Change
struct CodexFileChange: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let path: String
    let action: FileAction
    let diff: String?

    init(id: UUID = UUID(), path: String, action: FileAction, diff: String? = nil) {
        self.id = id
        self.path = path
        self.action = action
        self.diff = diff
    }
}

enum FileAction: String, Codable, Sendable {
    case created
    case modified
    case deleted

    var symbol: String {
        switch self {
        case .created: "plus.circle.fill"
        case .modified: "pencil.circle.fill"
        case .deleted: "minus.circle.fill"
        }
    }
}

// MARK: - Codex Model
enum CodexModel: String, CaseIterable, Sendable, Identifiable {
    case gpt5_3Codex = "gpt-5.3-codex"
    case gpt5_2Codex = "gpt-5.2-codex"
    case gpt5_1CodexMax = "gpt-5.1-codex-max"
    case gpt5_1CodexMini = "gpt-5.1-codex-mini"
    case gpt5_1Codex = "gpt-5.1-codex"
    case gpt5Codex = "gpt-5-codex"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gpt5_3Codex: "GPT-5.3 Codex"
        case .gpt5_2Codex: "GPT-5.2 Codex"
        case .gpt5_1CodexMax: "GPT-5.1 Codex Max"
        case .gpt5_1CodexMini: "GPT-5.1 Codex Mini"
        case .gpt5_1Codex: "GPT-5.1 Codex"
        case .gpt5Codex: "GPT-5 Codex"
        }
    }
}
