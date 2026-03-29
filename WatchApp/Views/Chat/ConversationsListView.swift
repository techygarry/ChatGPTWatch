import SwiftUI
import SwiftData

struct ConversationsListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var convList: [Conversation] = []

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.sm) {
                // New Chat
                NavigationLink {
                    NewChatView()
                } label: {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                        Text("New Chat")
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                        Spacer()
                    }
                    .padding(DesignTokens.Spacing.md)
                    .glassEffect(.regular.tint(DesignTokens.Colors.chatGPTGreen), in: .rect(cornerRadius: DesignTokens.Radius.medium))
                }
                .buttonStyle(.plain)

                if convList.isEmpty {
                    // Empty state
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 28))
                            .foregroundStyle(DesignTokens.Colors.chatGPTGreen.opacity(0.5))
                        Text("No conversations yet")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.xl)
                } else {
                    ForEach(convList) { conv in
                        NavigationLink {
                            ChatDetailView(conversationId: conv.id)
                        } label: {
                            ConversationRow(conversation: conv)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xs)
        }
        .navigationTitle("Chat")
        .onAppear {
            appState.chatVM.loadConversations(context: modelContext)
            convList = appState.chatVM.conversations
        }
        .onChange(of: appState.chatVM.stateVersion) { _, _ in
            convList = appState.chatVM.conversations
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack {
                Text(conversation.title)
                    .font(DesignTokens.Typography.bodyMedium)
                    .lineLimit(1)
                Spacer()
                Text(conversation.updatedAt.relativeString)
                    .font(DesignTokens.Typography.timestamp)
                    .foregroundStyle(.tertiary)
            }

            if let lastMessage = conversation.messages.last(where: { $0.role == .assistant }) {
                Text(lastMessage.content.firstLine.truncated(to: 40))
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: DesignTokens.Spacing.xs) {
                Circle()
                    .fill(DesignTokens.Colors.chatGPTGreen)
                    .frame(width: 5, height: 5)
                Text(GPTModel(rawValue: conversation.model)?.displayName ?? conversation.model)
                    .font(DesignTokens.Typography.micro)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .glassEffect(.regular, in: .rect(cornerRadius: DesignTokens.Radius.medium))
    }
}
