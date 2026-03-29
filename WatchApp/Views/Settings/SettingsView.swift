import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var showClearConfirm = false
    @State private var apiKeyInput = ""
    @State private var showAPIKey = false

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.md) {
                // Account Section
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Label("Account", systemImage: "person.crop.circle.fill")
                        .font(DesignTokens.Typography.micro)
                        .foregroundStyle(DesignTokens.Colors.chatGPTGreen)

                    if appState.settingsVM.hasAPIKey {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            ZStack {
                                Circle()
                                    .fill(DesignTokens.Colors.successGreen.opacity(0.15))
                                    .frame(width: 24, height: 24)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(DesignTokens.Colors.successGreen)
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Connected")
                                    .font(DesignTokens.Typography.bodyMedium)
                                    .foregroundStyle(.white)
                                Text("ChatGPT Plus / Pro")
                                    .font(DesignTokens.Typography.micro)
                                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                            }
                        }

                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Button {
                                apiKeyInput = ""
                                showAPIKey = true
                            } label: {
                                Text("Update Key")
                                    .font(DesignTokens.Typography.micro)
                            }
                            .buttonStyle(.bordered)
                            .tint(DesignTokens.Colors.chatGPTGreen)

                            Button {
                                appState.authService.signOut()
                                appState.settingsVM.clearAllData()
                            } label: {
                                Text("Sign Out")
                                    .font(DesignTokens.Typography.micro)
                            }
                            .buttonStyle(.bordered)
                            .tint(DesignTokens.Colors.errorRed)
                        }
                    } else {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            ZStack {
                                Circle()
                                    .fill(DesignTokens.Colors.warningAmber.opacity(0.15))
                                    .frame(width: 24, height: 24)
                                Image(systemName: "exclamationmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(DesignTokens.Colors.warningAmber)
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Not connected")
                                    .font(DesignTokens.Typography.bodyMedium)
                                    .foregroundStyle(DesignTokens.Colors.warningAmber)
                                Text("Requires ChatGPT subscription")
                                    .font(DesignTokens.Typography.micro)
                                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                            }
                        }

                        Button {
                            showAPIKey = true
                        } label: {
                            HStack(spacing: DesignTokens.Spacing.xs) {
                                Image(systemName: "key.fill")
                                    .font(.system(size: 9))
                                Text("Connect Account")
                                    .font(DesignTokens.Typography.caption)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(DesignTokens.Colors.chatGPTGreen)
                    }
                }
                .glassCard()

                // Chat Model
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Label("Chat Model", systemImage: "cpu")
                        .font(DesignTokens.Typography.micro)
                        .foregroundStyle(DesignTokens.Colors.chatGPTGreen)

                    Picker("Model", selection: Bindable(appState.settingsVM).selectedChatModel) {
                        ForEach(GPTModel.allCases) { model in
                            Text(model.displayName).tag(model)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .onChange(of: appState.settingsVM.selectedChatModel) { _, _ in
                        appState.settingsVM.saveChatModel()
                    }
                }
                .glassCard()

                // Toggles
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Toggle(isOn: Bindable(appState.settingsVM).hapticEnabled) {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                                .frame(width: 16)
                            Text("Haptics")
                                .font(DesignTokens.Typography.body)
                        }
                    }
                    .onChange(of: appState.settingsVM.hapticEnabled) { _, _ in
                        appState.settingsVM.saveHapticSetting()
                    }

                    Divider()
                        .background(DesignTokens.Colors.border)

                    Toggle(isOn: Bindable(appState.settingsVM).voiceEnabled) {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                                .frame(width: 16)
                            Text("Voice Input")
                                .font(DesignTokens.Typography.body)
                        }
                    }
                    .onChange(of: appState.settingsVM.voiceEnabled) { _, _ in
                        appState.settingsVM.saveVoiceSetting()
                    }
                }
                .tint(DesignTokens.Colors.chatGPTGreen)
                .glassCard()

                // Clear Data
                Button {
                    showClearConfirm = true
                } label: {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                        Text("Clear All Data")
                            .font(DesignTokens.Typography.caption)
                    }
                    .foregroundStyle(DesignTokens.Colors.errorRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(DesignTokens.Colors.errorRed.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                            .strokeBorder(DesignTokens.Colors.errorRed.opacity(0.2), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)

                // Version
                VStack(spacing: DesignTokens.Spacing.xxs) {
                    Text("ChatGPT Watch")
                        .font(DesignTokens.Typography.micro)
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                    Text("v1.0.0")
                        .font(DesignTokens.Typography.timestamp)
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
                .padding(.top, DesignTokens.Spacing.sm)
            }
            .padding(.horizontal, DesignTokens.Spacing.xs)
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showAPIKey) {
            APIKeyInputView(apiKey: $apiKeyInput) {
                appState.settingsVM.apiKey = apiKeyInput
                appState.settingsVM.saveAPIKey()
                showAPIKey = false
            }
        }
        .confirmationDialog("Clear all data?", isPresented: $showClearConfirm) {
            Button("Clear All", role: .destructive) {
                appState.settingsVM.clearAllData()
            }
        }
        .onAppear {
            appState.settingsVM.loadSettings()
        }
    }
}

// MARK: - API Key Input Sheet

struct APIKeyInputView: View {
    @Binding var apiKey: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ZStack {
                Circle()
                    .fill(DesignTokens.Colors.chatGPTGreen.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "key.fill")
                    .font(.title3)
                    .foregroundStyle(DesignTokens.Gradients.greenAccent)
            }

            Text("API Key")
                .font(DesignTokens.Typography.sectionHeader)
                .foregroundStyle(.white)

            TextField("sk-...", text: $apiKey)
                .font(DesignTokens.Typography.code)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            HStack(spacing: DesignTokens.Spacing.sm) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .tint(DesignTokens.Colors.textSecondary)

                Button("Save") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignTokens.Colors.chatGPTGreen)
                .disabled(apiKey.trimmed.isEmpty)
            }
        }
        .padding()
        .background(DesignTokens.Colors.surfaceDark)
    }
}
