import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.xs) {
            if isUser { Spacer(minLength: 16) }

            if !isUser {
                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                    .frame(width: 20, height: 20)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: DesignTokens.Spacing.xxs) {
                HStack(spacing: 0) {
                    Text(message.content)
                        .font(DesignTokens.Typography.body)
                        .lineLimit(nil)

                    if message.isStreaming {
                        Text("\u{2588}")
                            .font(DesignTokens.Typography.body)
                            .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                            .opacity(0.9)
                            .animation(DesignTokens.Animation.glow, value: message.isStreaming)
                    }
                }
                .chatBubbleStyle(isUser: isUser)

                Text(message.timestamp.shortTime)
                    .font(DesignTokens.Typography.timestamp)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, DesignTokens.Spacing.xs)
            }

            if isUser {
                Image(systemName: "person.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
            }

            if !isUser { Spacer(minLength: 16) }
        }
    }
}
