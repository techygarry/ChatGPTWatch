import SwiftUI

// LoginView is kept for manual API key entry from Settings
struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var apiKey = ""
    @State private var isValidating = false
    @State private var errorMessage: String?
    @FocusState private var isKeyFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    Image("ChatGPTLogo")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                        .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Label("API Key", systemImage: "key.fill")
                            .font(DesignTokens.Typography.micro)
                            .foregroundStyle(DesignTokens.Colors.chatGPTGreen)

                        TextField("sk-...", text: $apiKey)
                            .font(DesignTokens.Typography.code)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($isKeyFocused)
                    }
                    .cardStyle()

                    Button {
                        connect()
                    } label: {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            if isValidating { ProgressView().scaleEffect(0.8) }
                            Text(isValidating ? "Connecting..." : "Connect")
                                .font(DesignTokens.Typography.bodyMedium)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(DesignTokens.Colors.chatGPTGreen)
                    .disabled(apiKey.trimmed.isEmpty || isValidating)

                    if let error = errorMessage {
                        Label(error, systemImage: "exclamationmark.circle.fill")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.errorRed)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xs)
            }
            .navigationTitle("Sign In")
        }
    }

    private func connect() {
        isValidating = true
        errorMessage = nil
        let key = apiKey.trimmed

        Task {
            appState.authService.loginWithAPIKey(key)
            let valid = await appState.authService.validateToken()
            isValidating = false

            if valid {
                HapticManager.shared.play(.responseComplete)
                appState.settingsVM.apiKey = key
                appState.settingsVM.saveAPIKey()
            } else {
                withAnimation(DesignTokens.Animation.spring) {
                    errorMessage = "Invalid API key"
                }
                appState.authService.signOut()
                HapticManager.shared.play(.error)
            }
        }
    }
}
