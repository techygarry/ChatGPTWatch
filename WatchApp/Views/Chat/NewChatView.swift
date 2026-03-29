import SwiftUI

struct NewChatView: View {
    @Environment(AppState.self) private var appState
    @State private var inputText = ""
    @State private var selectedModel: GPTModel = .gpt5_4
    @State private var showVoice = false
    @State private var navigateToChat = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.md) {
                // Hero
                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                    .padding(.top, DesignTokens.Spacing.sm)

                // Model
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Label("Model", systemImage: "cpu")
                        .font(DesignTokens.Typography.micro)
                        .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                    Picker("Model", selection: $selectedModel) {
                        ForEach(GPTModel.allCases) { model in
                            Text(model.displayName).tag(model)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                .cardStyle()

                // Input
                VStack(spacing: DesignTokens.Spacing.sm) {
                    TextField("Ask anything...", text: $inputText, axis: .vertical)
                        .font(DesignTokens.Typography.body)
                        .focused($isInputFocused)
                        .lineLimit(1...4)

                    HStack {
                        Button {
                            showVoice = true
                        } label: {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.glass)
                        .tint(DesignTokens.Colors.chatGPTGreen)

                        Spacer()

                        Button { startChat() } label: {
                            Label("Send", systemImage: "arrow.up")
                                .font(DesignTokens.Typography.caption)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(DesignTokens.Colors.chatGPTGreen)
                        .disabled(inputText.trimmed.isEmpty)
                    }
                }
                .cardStyle()

                // Suggestions
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Suggestions")
                        .font(DesignTokens.Typography.micro)
                        .foregroundStyle(.secondary)

                    ForEach(Array(quickPrompts.enumerated()), id: \.offset) { index, prompt in
                        Button { inputText = prompt } label: {
                            HStack(spacing: DesignTokens.Spacing.sm) {
                                Image(systemName: promptIcons[index])
                                    .font(.system(size: 10))
                                    .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                                    .frame(width: 14)
                                Text(prompt)
                                    .font(DesignTokens.Typography.caption)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(DesignTokens.Spacing.sm)
                            .glassEffect(.regular, in: .rect(cornerRadius: DesignTokens.Radius.small))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xs)
        }
        .navigationTitle("New Chat")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToChat) {
            if let conv = appState.chatVM.currentConversation {
                ChatDetailView(conversationId: conv.id)
            }
        }
        .sheet(isPresented: $showVoice) {
            VoiceModeView { text in
                inputText = text
                startChat()
            }
        }
        .onAppear {
            selectedModel = appState.settingsVM.selectedChatModel
        }
    }

    private func startChat() {
        guard !inputText.trimmed.isEmpty else { return }
        let text = inputText
        let model = selectedModel.rawValue
        inputText = ""
        appState.chatVM.newConversation(model: model)
        navigateToChat = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            appState.chatVM.sendMessage(text)
        }
    }

    private var quickPrompts: [String] {
        ["Explain quantum computing", "Write a Python script", "Debug my code", "Summarize this topic"]
    }
    private var promptIcons: [String] {
        ["atom", "chevron.left.forwardslash.chevron.right", "ladybug", "text.quote"]
    }
}
