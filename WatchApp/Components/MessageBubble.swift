import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.xs) {
            if isUser { Spacer(minLength: 16) }

            if !isUser {
                ZStack {
                    Circle()
                        .fill(DesignTokens.Colors.chatGPTGreen.opacity(0.15))
                        .frame(width: 22, height: 22)
                    Image(systemName: "brain.head.profile.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                }
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: DesignTokens.Spacing.xxs) {
                HStack(spacing: 0) {
                    Text(message.content)
                        .font(DesignTokens.Typography.body)
                        .foregroundStyle(.white)
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
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                    .padding(.horizontal, DesignTokens.Spacing.xs)
            }

            if isUser {
                ZStack {
                    Circle()
                        .fill(DesignTokens.Colors.surfaceElevated)
                        .frame(width: 22, height: 22)
                    Image(systemName: "person.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }

            if !isUser { Spacer(minLength: 16) }
        }
    }
}
