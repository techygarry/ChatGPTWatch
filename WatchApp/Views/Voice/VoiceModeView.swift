import SwiftUI

struct VoiceModeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var dictatedText = ""
    @FocusState private var isTextFieldFocused: Bool

    let onTextReceived: (String) -> Void

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Header
            Image("ChatGPTLogo")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                .frame(width: 24, height: 24)

            Text("Speak or type")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(.secondary)

            // TextField triggers watchOS system dictation when tapped
            TextField("Tap to dictate...", text: $dictatedText, axis: .vertical)
                .font(DesignTokens.Typography.body)
                .lineLimit(1...5)
                .focused($isTextFieldFocused)
                .padding(DesignTokens.Spacing.sm)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))

            // Send button
            if !dictatedText.trimmed.isEmpty {
                Button {
                    onTextReceived(dictatedText.trimmed)
                    dismiss()
                } label: {
                    Label("Send", systemImage: "arrow.up")
                        .font(DesignTokens.Typography.bodyMedium)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignTokens.Colors.chatGPTGreen)
            }
        }
        .padding()
        .onAppear {
            // Auto-focus to immediately trigger dictation UI
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
}
