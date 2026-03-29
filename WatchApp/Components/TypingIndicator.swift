import SwiftUI

struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.xs) {
            Image(systemName: "brain.head.profile.fill")
                .font(.system(size: 12))
                .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                .frame(width: 20, height: 20)

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(DesignTokens.Colors.chatGPTGreen.opacity(animating ? 0.8 : 0.3))
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
            .glassEffect(.regular, in: .rect(cornerRadius: DesignTokens.Radius.medium))

            Spacer(minLength: 16)
        }
        .onAppear { animating = true }
    }
}
