import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class AppState {
    let openAIService = OpenAIService()
    let codexService = CodexService()
    let ttsService = TTSService()

    let authService = AuthService()
    private(set) var chatVM: ChatViewModel
    private(set) var codexVM: CodexViewModel
    private(set) var settingsVM: SettingsViewModel

    var isInitialized = false

    init() {
        let oaiService = OpenAIService()
        let cdxService = CodexService()
        self.chatVM = ChatViewModel(openAIService: oaiService)
        self.codexVM = CodexViewModel(codexService: cdxService)
        self.settingsVM = SettingsViewModel()
    }

    func initialize(modelContext: ModelContext) {
        guard !isInitialized else { return }
        chatVM.loadConversations(context: modelContext)
        codexVM.setModelContext(modelContext)
        settingsVM.loadSettings()
        isInitialized = true

        Task {
            await authService.validateToken()
        }
    }
}
