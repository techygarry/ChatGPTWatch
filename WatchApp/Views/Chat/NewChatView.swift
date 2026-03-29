import SwiftUI

struct NewChatView: View {
    @Environment(AppState.self) private var appState
    @State private var inputText = ""
    @State private var selectedModel: GPTModel = .gpt5_4
    @State private var showVoice = false
    @State private var navigateToChat = false
    @State private var appear = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.md) {
                // Hero
                VStack(spacing: DesignTokens.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(DesignTokens.Colors.chatGPTGreen.opacity(0.12))
                            .frame(width: 52, height: 52)
                            .blur(radius: 6)

                        Circle()
                            .fill(DesignTokens.Colors.surfaceMid)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .strokeBorder(DesignTokens.Gradients.greenAccent, lineWidth: 1.5)
                            )

                        Image(systemName: "brain.head.profile.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(DesignTokens.Gradients.greenAccent)
                    }
                    .scaleEffect(appear ? 1.0 : 0.7)
                    .opacity(appear ? 1.0 : 0)

                    Text("New Chat")
                        .font(DesignTokens.Typography.sectionHeader)
                        .foregroundStyle(.white)
                }
                .padding(.top, DesignTokens.Spacing.sm)

                // Model Picker
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
                .glassCard()

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
                                .font(.system(size: 11))
                                .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                                .frame(width: 28, height: 28)
                                .background(DesignTokens.Colors.chatGPTGreen.opacity(0.12))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button {
                            startChat()
                        } label: {
                            HStack(spacing: DesignTokens.Spacing.xs) {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 10, weight: .bold))
                                Text("Send")
                                    .font(DesignTokens.Typography.caption)
                            }
                            .padding(.horizontal, DesignTokens.Spacing.md)
                            .padding(.vertical, DesignTokens.Spacing.xs)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(DesignTokens.Colors.chatGPTGreen)
                        .disabled(inputText.trimmed.isEmpty)
                    }
                }
                .glassCard()

                // Quick Prompts
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Suggestions")
                        .font(DesignTokens.Typography.micro)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)

                    ForEach(Array(quickPrompts.enumerated()), id: \.offset) { index, prompt in
                        Button {
                            inputText = prompt
                        } label: {
                            HStack(spacing: DesignTokens.Spacing.sm) {
                                Image(systemName: promptIcons[index])
                                    .font(.system(size: 10))
                                    .foregroundStyle(DesignTokens.Colors.chatGPTGreen.opacity(0.7))
                                    .frame(width: 16)
                                Text(prompt)
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 8))
                                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                            }
                            .padding(DesignTokens.Spacing.sm)
                            .background(DesignTokens.Colors.surfaceMid)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                                    .strokeBorder(DesignTokens.Colors.glassStroke, lineWidth: 0.5)
                            )
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
            withAnimation(DesignTokens.Animation.bouncy.delay(0.1)) {
                appear = true
            }
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
        [
            "Explain quantum computing",
            "Write a Python script",
            "Debug my code",
            "Summarize this topic"
        ]
    }

    private var promptIcons: [String] {
        ["atom", "chevron.left.forwardslash.chevron.right", "ladybug", "text.quote"]
    }
}
