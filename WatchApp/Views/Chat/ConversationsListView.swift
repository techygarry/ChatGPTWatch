import SwiftUI
import SwiftData

struct ConversationsListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var convList: [Conversation] = []
    @State private var version = 0

    var body: some View {
        List {
            // New Chat button — hero style
            NavigationLink {
                NewChatView()
            } label: {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(DesignTokens.Colors.chatGPTGreen.opacity(0.15))
                            .frame(width: 28, height: 28)
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                    }
                    Text("New Chat")
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                }
            }
            .listRowBackground(
                DesignTokens.Colors.surfaceMid
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
            )

            if convList.isEmpty {
                VStack(spacing: DesignTokens.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(DesignTokens.Colors.chatGPTGreen.opacity(0.08))
                            .frame(width: 56, height: 56)
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 24))
                            .foregroundStyle(DesignTokens.Colors.chatGPTGreen.opacity(0.5))
                    }
                    Text("No conversations yet")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                    Text("Start a new chat above")
                        .font(DesignTokens.Typography.timestamp)
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.xl)
                .listRowBackground(Color.clear)
            } else {
                ForEach(convList) { conv in
                    NavigationLink {
                        ChatDetailView(conversationId: conv.id)
                    } label: {
                        ConversationRow(conversation: conv)
                    }
                    .listRowBackground(
                        DesignTokens.Colors.surfaceMid
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
                    )
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let conv = convList[index]
                        appState.chatVM.deleteConversation(conv, context: modelContext)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("ChatGPT")
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
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineLimit(1)
                Spacer()
                Text(conversation.updatedAt.relativeString)
                    .font(DesignTokens.Typography.timestamp)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            if let lastMessage = conversation.messages.last(where: { $0.role == .assistant }) {
                Text(lastMessage.content.firstLine.truncated(to: 40))
                    .font(DesignTokens.Typography.captionLight)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .lineLimit(1)
            }

            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 5))
                    .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                Text(GPTModel(rawValue: conversation.model)?.displayName ?? conversation.model)
                    .font(DesignTokens.Typography.micro)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
    }
}
