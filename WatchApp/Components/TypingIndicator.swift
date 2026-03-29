import SwiftUI

struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.xs) {
            ZStack {
                Circle()
                    .fill(DesignTokens.Colors.chatGPTGreen.opacity(0.15))
                    .frame(width: 22, height: 22)
                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
            }

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(DesignTokens.Colors.chatGPTGreen.opacity(animating ? 0.9 : 0.3))
                        .frame(width: 5, height: 5)
                        .offset(y: animating ? -3 : 0)
                        .animation(
                            .easeInOut(duration: 0.45)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.12),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(DesignTokens.Colors.assistantBg)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous)
                    .strokeBorder(DesignTokens.Colors.glassStroke, lineWidth: 0.5)
            )

            Spacer(minLength: 16)
        }
        .onAppear { animating = true }
    }
}
