import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    var apiKey: String = ""
    var selectedChatModel: GPTModel = .gpt5_4
    var selectedCodexModel: CodexModel = .gpt5_3Codex
    var hapticEnabled: Bool = true
    var voiceEnabled: Bool = true
    var hasAPIKey: Bool { !apiKey.isEmpty }

    private let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName) ?? .standard

    func loadSettings() {
        apiKey = KeychainService.shared.load(key: KeychainKeys.openAIAPIKey) ?? ""

        if let chatModel = defaults.string(forKey: AppConstants.UserDefaultsKeys.selectedChatModel),
           let model = GPTModel(rawValue: chatModel) {
            selectedChatModel = model
        }

        if let codexModel = defaults.string(forKey: AppConstants.UserDefaultsKeys.selectedCodexModel),
           let model = CodexModel(rawValue: codexModel) {
            selectedCodexModel = model
        }

        hapticEnabled = defaults.object(forKey: AppConstants.UserDefaultsKeys.hapticEnabled) as? Bool ?? true
        voiceEnabled = defaults.object(forKey: AppConstants.UserDefaultsKeys.voiceEnabled) as? Bool ?? true
    }

    func saveAPIKey() {
        KeychainService.shared.save(key: KeychainKeys.openAIAPIKey, value: apiKey)
    }

    func saveChatModel() {
        defaults.set(selectedChatModel.rawValue, forKey: AppConstants.UserDefaultsKeys.selectedChatModel)
    }

    func saveCodexModel() {
        defaults.set(selectedCodexModel.rawValue, forKey: AppConstants.UserDefaultsKeys.selectedCodexModel)
    }

    func saveHapticSetting() {
        defaults.set(hapticEnabled, forKey: AppConstants.UserDefaultsKeys.hapticEnabled)
    }

    func saveVoiceSetting() {
        defaults.set(voiceEnabled, forKey: AppConstants.UserDefaultsKeys.voiceEnabled)
    }

    func clearAllData() {
        KeychainService.shared.delete(key: KeychainKeys.openAIAPIKey)
        apiKey = ""
        let keys = [
            AppConstants.UserDefaultsKeys.selectedChatModel,
            AppConstants.UserDefaultsKeys.selectedCodexModel,
            AppConstants.UserDefaultsKeys.hapticEnabled,
            AppConstants.UserDefaultsKeys.voiceEnabled
        ]
        keys.forEach { defaults.removeObject(forKey: $0) }
        loadSettings()
    }
}
