import SwiftUI
import SwiftData

struct ChatDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    let conversationId: UUID

    @State private var inputText = ""
    @State private var showVoice = false
    @State private var displayedStreamText = ""
    @State private var localIsStreaming = false
    @FocusState private var isInputFocused: Bool

    private let streamTimer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    let msgs = (appState.chatVM.currentConversation?.messages ?? [])
                        .filter { $0.role != .system }
                    ForEach(msgs) { message in
                        MessageBubble(message: message)
                    }

                    // Streaming state
                    if localIsStreaming {
                        if !displayedStreamText.isEmpty {
                            HStack(alignment: .top, spacing: DesignTokens.Spacing.xs) {
                                ZStack {
                                    Circle()
                                        .fill(DesignTokens.Colors.chatGPTGreen.opacity(0.15))
                                        .frame(width: 22, height: 22)
                                    Image(systemName: "brain.head.profile.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                                }

                                Text(displayedStreamText)
                                    .font(DesignTokens.Typography.body)
                                    .foregroundStyle(.white)
                                    .chatBubbleStyle(isUser: false)

                                Spacer(minLength: 16)
                            }
                        } else {
                            TypingIndicator()
                        }
                    }

                    if let error = appState.chatVM.errorMessage {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption2)
                            Text(error)
                                .font(DesignTokens.Typography.caption)
                        }
                        .foregroundStyle(DesignTokens.Colors.errorRed)
                        .padding(DesignTokens.Spacing.sm)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xs)
                .padding(.bottom, DesignTokens.Spacing.sm)
            }

            // Input Bar
            HStack(spacing: DesignTokens.Spacing.sm) {
                if localIsStreaming {
                    Button {
                        appState.chatVM.stopStreaming()
                        localIsStreaming = false
                        displayedStreamText = ""
                    } label: {
                        Image(systemName: "stop.circle.fill")
                            .foregroundStyle(DesignTokens.Colors.errorRed)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        showVoice = true
                    } label: {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                            .frame(width: 26, height: 26)
                            .background(DesignTokens.Colors.chatGPTGreen.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    TextField("Message", text: $inputText)
                        .font(DesignTokens.Typography.body)
                        .focused($isInputFocused)
                        .submitLabel(.send)
                        .onSubmit { send() }

                    Button { send() } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(
                                inputText.trimmed.isEmpty
                                    ? DesignTokens.Colors.textTertiary
                                    : DesignTokens.Colors.chatGPTGreen
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.trimmed.isEmpty)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(
                DesignTokens.Colors.surfaceMid
                    .overlay(
                        Rectangle()
                            .fill(DesignTokens.Colors.glassStroke)
                            .frame(height: 0.5),
                        alignment: .top
                    )
            )
        }
        .navigationTitle(appState.chatVM.currentConversation?.title ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showVoice) {
            VoiceModeView { text in
                inputText = text
                send()
            }
        }
        .onAppear {
            if let conv = appState.chatVM.conversations.first(where: { $0.id == conversationId }) {
                appState.chatVM.selectConversation(conv)
            }
        }
        .onReceive(streamTimer) { _ in
            let streaming = appState.chatVM.isStreaming
            if streaming != localIsStreaming {
                localIsStreaming = streaming
            }
            if streaming {
                let text = appState.chatVM.streamedText
                if text != displayedStreamText {
                    displayedStreamText = text
                }
            } else if !displayedStreamText.isEmpty {
                displayedStreamText = ""
            }
        }
    }

    private func send() {
        let text = inputText
        inputText = ""
        isInputFocused = false
        displayedStreamText = ""
        localIsStreaming = true
        appState.chatVM.sendMessage(text)
    }
}
