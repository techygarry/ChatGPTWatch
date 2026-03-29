import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    var onSpeak: (() -> Void)?
    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.xs) {
            if isUser { Spacer(minLength: 16) }

            if !isUser {
                Image("ChatGPTLogo")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                    .frame(width: 16, height: 16)
                    .padding(.top, 2)
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

                HStack(spacing: DesignTokens.Spacing.sm) {
                    Text(message.timestamp.shortTime)
                        .font(DesignTokens.Typography.timestamp)
                        .foregroundStyle(.tertiary)

                    // Speak button for assistant messages
                    if !isUser && !message.isStreaming, let onSpeak {
                        Button {
                            onSpeak()
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xs)
            }

            if isUser {
                Image(systemName: "person.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .frame(width: 16, height: 16)
                    .padding(.top, 2)
            }

            if !isUser { Spacer(minLength: 16) }
        }
    }
}
