import Foundation

// MARK: - API Key Constants
enum KeychainKeys {
    static let openAIAPIKey = "openai_api_key"
}

// MARK: - App Group
enum AppGroupConstants {
    static let suiteName = "group.com.chatgpt.watch"
}

// MARK: - Watch Connectivity Messages
enum WatchMessage {
    static let apiKeyUpdate = "apiKeyUpdate"
    static let settingsSync = "settingsSync"
    static let apiKeyField = "apiKey"
}
