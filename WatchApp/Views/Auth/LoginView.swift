import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var apiKey = ""
    @State private var isValidating = false
    @State private var showHelp = false
    @State private var errorMessage: String?
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @FocusState private var isKeyFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Animated Logo
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        ZStack {
                            // Glow ring
                            Circle()
                                .fill(DesignTokens.Colors.chatGPTGreen.opacity(0.15))
                                .frame(width: 72, height: 72)
                                .blur(radius: 10)

                            Circle()
                                .fill(DesignTokens.Colors.surfaceMid)
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            DesignTokens.Gradients.greenAccent,
                                            lineWidth: 1.5
                                        )
                                )

                            Image(systemName: "brain.head.profile.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(DesignTokens.Gradients.greenAccent)
                        }
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                        Text("ChatGPT")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Sign in with your\nOpenAI account")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, DesignTokens.Spacing.md)

                    // Content
                    VStack(spacing: DesignTokens.Spacing.md) {
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
                        .glassCard()

                        // Connect Button
                        Button {
                            connect()
                        } label: {
                            HStack(spacing: DesignTokens.Spacing.sm) {
                                if isValidating {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                }
                                Text(isValidating ? "Connecting..." : "Connect")
                                    .font(DesignTokens.Typography.bodyMedium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignTokens.Spacing.xs)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(DesignTokens.Colors.chatGPTGreen)
                        .disabled(apiKey.trimmed.isEmpty || isValidating)
                        .accentGlow(color: DesignTokens.Colors.chatGPTGreen)

                        if let error = errorMessage {
                            HStack(spacing: DesignTokens.Spacing.xs) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption2)
                                Text(error)
                                    .font(DesignTokens.Typography.caption)
                            }
                            .foregroundStyle(DesignTokens.Colors.errorRed)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }

                        // Help Toggle
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
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                        }
                        .buttonStyle(.plain)

                        if showHelp {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                HelpStep(number: "1", text: "Go to platform.openai.com")
                                HelpStep(number: "2", text: "Sign in to your account")
                                HelpStep(number: "3", text: "API keys > Create new key")
                                HelpStep(number: "4", text: "Paste key above")

                                Text("Included with Plus / Pro")
                                    .font(DesignTokens.Typography.micro)
                                    .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                                    .padding(.top, DesignTokens.Spacing.xxs)
                            }
                            .glassCard()
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.96)),
                                removal: .opacity
                            ))
                        }
                    }
                    .opacity(contentOpacity)

                    // iPhone hint
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "iphone")
                            .font(.system(size: 10))
                        Text("Or set up from iPhone app")
                            .font(DesignTokens.Typography.timestamp)
                    }
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                    .padding(.top, DesignTokens.Spacing.sm)
                }
                .padding(.horizontal, DesignTokens.Spacing.xs)
            }
            .background(DesignTokens.Colors.surfaceDark)
            .navigationTitle("Sign In")
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
                withAnimation(.easeOut(duration: 0.5).delay(0.25)) {
                    contentOpacity = 1.0
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
                    errorMessage = "Invalid API key. Check and try again."
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
                .background(DesignTokens.Gradients.greenAccent)
                .clipShape(Circle())
            Text(text)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
        }
    }
}
