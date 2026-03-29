import Foundation

enum AppConstants {
    static let openAIBaseURL = "https://api.openai.com/v1"
    static let appGroup = "group.com.chatgpt.watch"
    static let maxConversationHistory = 20
    static let maxTokens = 2048
    static let streamingCharDelay: TimeInterval = 0.02
    static let pollingInterval: TimeInterval = 3.0
    static let defaultChatModel = GPTModel.gpt5_4
    static let defaultCodexModel = CodexModel.gpt5_3Codex

    enum UserDefaultsKeys {
        static let selectedChatModel = "selectedChatModel"
        static let selectedCodexModel = "selectedCodexModel"
        static let hapticEnabled = "hapticEnabled"
        static let voiceEnabled = "voiceEnabled"
        static let lastSyncDate = "lastSyncDate"
    }
}
