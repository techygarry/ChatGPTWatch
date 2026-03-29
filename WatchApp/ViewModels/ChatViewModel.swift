import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class ChatViewModel {
    // ALL state is ObservationIgnored — views poll via timer to avoid feedback loops
    @ObservationIgnored var conversations: [Conversation] = []
    @ObservationIgnored var currentConversation: Conversation?
    @ObservationIgnored var errorMessage: String?
    @ObservationIgnored var isStreaming = false
    @ObservationIgnored var streamedText = ""

    // Single counter that views observe to know something changed
    var stateVersion = 0
    private func notifyChange() { stateVersion += 1 }

    // Called when a response finishes streaming — views can use this for auto-speak
    var lastCompletedResponse: String?

    let openAIService: OpenAIService
    private var modelContext: ModelContext?
    private var streamTask: Task<Void, Never>?

    init(openAIService: OpenAIService) {
        self.openAIService = openAIService
    }

    // MARK: - Conversation Management
    func newConversation(model: String = GPTModel.gpt5_4.rawValue) {
        let conv = Conversation(model: model)
        currentConversation = conv
    }

    func selectConversation(_ conv: Conversation) {
        currentConversation = conv
        streamedText = ""
        errorMessage = nil
        notifyChange()
    }

    func loadConversations(context: ModelContext) {
        self.modelContext = context
        let descriptor = FetchDescriptor<SDConversation>(sortBy: [SortDescriptor(\SDConversation.updatedAt, order: .reverse)])
        if let results = try? context.fetch(descriptor) {
            conversations = results.map { $0.toConversation() }
            notifyChange()
        }
    }

    func deleteConversation(_ conv: Conversation, context: ModelContext) {
        let id = conv.id
        let descriptor = FetchDescriptor<SDConversation>(predicate: #Predicate { $0.id == id })
        if let sdConv = try? context.fetch(descriptor).first {
            context.delete(sdConv)
            try? context.save()
        }
        conversations.removeAll { $0.id == conv.id }
        if currentConversation?.id == conv.id {
            currentConversation = nil
        }
    }

    // MARK: - Send Message
    func sendMessage(_ text: String) {
        guard !text.trimmed.isEmpty else { return }

        if currentConversation == nil {
            newConversation()
        }

        guard var conv = currentConversation else { return }

        // Add user message
        let userMessage = ChatMessage(role: .user, content: text.trimmed)
        conv.messages.append(userMessage)
        conv.updatedAt = Date()
        currentConversation = conv

        HapticManager.shared.play(.messageSent)

        // Start streaming response
        streamedText = ""
        isStreaming = true
        errorMessage = nil

        let messages = conv.messages
            .filter { $0.role != .system && !$0.content.isEmpty }
            .suffix(AppConstants.maxConversationHistory)
            .map { (role: $0.role.rawValue, content: $0.content) }

        let model = conv.model
        let queryText = text.trimmed

        streamTask = Task {
            var fullText = ""
            let stream = self.openAIService.chat(messages: Array(messages), model: model)

            do {
                for try await chunk in stream {
                    if Task.isCancelled { break }

                    if let error = chunk.error {
                        self.errorMessage = error.localizedDescription
                        self.isStreaming = false
                        HapticManager.shared.play(.error)
                        return
                    }

                    if let delta = chunk.delta {
                        fullText += delta
                        self.streamedText = fullText
                    }

                    if chunk.isComplete {
                        break
                    }
                }

                // Finalize — add the completed assistant message to conversation
                self.isStreaming = false
                if !fullText.isEmpty {
                    let assistantMessage = ChatMessage(role: .assistant, content: fullText)
                    self.currentConversation?.messages.append(assistantMessage)
                    self.currentConversation?.updatedAt = Date()

                    // Auto-title
                    if self.currentConversation?.title == "New Chat", let firstMsg = self.currentConversation?.messages.first(where: { $0.role == .user }) {
                        self.currentConversation?.title = firstMsg.content.truncated(to: 30)
                    }

                    self.saveCurrentConversation()
                    CacheManager.shared.cacheResponse(query: queryText, response: fullText)
                    HapticManager.shared.play(.responseComplete)
                    self.lastCompletedResponse = fullText
                    self.notifyChange()
                }
            } catch {
                self.errorMessage = error.localizedDescription
                self.isStreaming = false
                self.notifyChange()
            }
        }
    }

    func stopStreaming() {
        streamTask?.cancel()
        openAIService.cancelStream()
        isStreaming = false
    }

    // MARK: - Persistence
    private func saveCurrentConversation() {
        guard let context = modelContext, var conv = currentConversation else { return }
        conv.updatedAt = Date()
        currentConversation = conv

        let convId = conv.id
        let descriptor = FetchDescriptor<SDConversation>(predicate: #Predicate { $0.id == convId })

        if let existing = try? context.fetch(descriptor).first {
            existing.title = conv.title
            existing.model = conv.model
            existing.updatedAt = conv.updatedAt
            // Remove old messages and add new
            existing.messages.removeAll()
            for msg in conv.messages where !msg.content.isEmpty {
                let sdMsg = SDMessage(id: msg.id, role: msg.role, content: msg.content, timestamp: msg.timestamp)
                sdMsg.conversation = existing
                existing.messages.append(sdMsg)
            }
        } else {
            let sdConv = SDConversation(id: conv.id, title: conv.title, model: conv.model, createdAt: conv.createdAt, updatedAt: conv.updatedAt)
            for msg in conv.messages where !msg.content.isEmpty {
                let sdMsg = SDMessage(id: msg.id, role: msg.role, content: msg.content, timestamp: msg.timestamp)
                sdMsg.conversation = sdConv
                sdConv.messages.append(sdMsg)
            }
            context.insert(sdConv)
        }

        try? context.save()

        // Refresh conversations list
        loadConversations(context: context)
    }
}
