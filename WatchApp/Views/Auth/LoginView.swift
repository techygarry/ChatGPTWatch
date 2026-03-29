import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var apiKey = ""
    @State private var isValidating = false
    @State private var showHelp = false
    @State private var errorMessage: String?
    @State private var appear = false
    @FocusState private var isKeyFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Logo
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "brain.head.profile.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                            .scaleEffect(appear ? 1.0 : 0.5)
                            .opacity(appear ? 1 : 0)

                        Text("ChatGPT")
                            .font(DesignTokens.Typography.largeTitle)

                        Text("Sign in with your\nOpenAI account")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, DesignTokens.Spacing.md)

                    // API Key Input
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

                    // Connect
                    Button {
                        connect()
                    } label: {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            if isValidating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isValidating ? "Connecting..." : "Connect")
                                .font(DesignTokens.Typography.bodyMedium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(DesignTokens.Colors.chatGPTGreen)
                    .disabled(apiKey.trimmed.isEmpty || isValidating)

                    if let error = errorMessage {
                        Label(error, systemImage: "exclamationmark.circle.fill")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.errorRed)
                    }

                    // Help
                    Button {
                        withAnimation(DesignTokens.Animation.spring) {
                            showHelp.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                            Text("How to get your key")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .rotationEffect(.degrees(showHelp ? 90 : 0))
                        }
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    if showHelp {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            HelpStep(number: "1", text: "Go to platform.openai.com")
                            HelpStep(number: "2", text: "Sign in to your account")
                            HelpStep(number: "3", text: "API keys > Create new key")
                            HelpStep(number: "4", text: "Paste key above")
                        }
                        .cardStyle()
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xs)
            }
            .navigationTitle("Sign In")
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    appear = true
                }
            }
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

struct HelpStep: View {
    let number: String
    let text: String

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Text(number)
                .font(DesignTokens.Typography.micro)
                .foregroundStyle(.white)
                .frame(width: 16, height: 16)
                .background(DesignTokens.Colors.chatGPTGreen)
                .clipShape(Circle())
            Text(text)
                .font(DesignTokens.Typography.caption)
        }
    }
}
