import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var showClearConfirm = false
    @State private var apiKeyInput = ""
    @State private var showAPIKey = false

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.md) {
                // Account
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Label("Account", systemImage: "person.crop.circle.fill")
                        .font(DesignTokens.Typography.micro)
                        .foregroundStyle(DesignTokens.Colors.chatGPTGreen)

                    if appState.settingsVM.hasAPIKey {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(DesignTokens.Colors.successGreen)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Connected")
                                    .font(DesignTokens.Typography.bodyMedium)
                                Text("ChatGPT Plus / Pro")
                                    .font(DesignTokens.Typography.micro)
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Button("Update Key") {
                                apiKeyInput = ""
                                showAPIKey = true
                            }
                            .font(DesignTokens.Typography.micro)
                            .buttonStyle(.glass)

                            Button("Sign Out") {
                                appState.authService.signOut()
                                appState.settingsVM.clearAllData()
                            }
                            .font(DesignTokens.Typography.micro)
                            .buttonStyle(.glass)
                            .tint(DesignTokens.Colors.errorRed)
                        }
                    } else {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(DesignTokens.Colors.warningAmber)
                            Text("Not connected")
                                .font(DesignTokens.Typography.bodyMedium)
                                .foregroundStyle(DesignTokens.Colors.warningAmber)
                        }

                        Button("Connect Account") {
                            apiKeyInput = ""
                            showAPIKey = true
                        }
                        .font(DesignTokens.Typography.caption)
                        .buttonStyle(.glassProminent)
                        .tint(DesignTokens.Colors.chatGPTGreen)
                    }
                }
                .cardStyle()

                // Model
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
                .cardStyle()

                // Toggles
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Toggle(isOn: Bindable(appState.settingsVM).hapticEnabled) {
                        Label("Haptics", systemImage: "hand.tap.fill")
                            .font(DesignTokens.Typography.body)
                    }
                    .onChange(of: appState.settingsVM.hapticEnabled) { _, _ in
                        appState.settingsVM.saveHapticSetting()
                    }

                    Toggle(isOn: Bindable(appState.settingsVM).voiceEnabled) {
                        Label("Voice Input", systemImage: "mic.fill")
                            .font(DesignTokens.Typography.body)
                    }
                    .onChange(of: appState.settingsVM.voiceEnabled) { _, _ in
                        appState.settingsVM.saveVoiceSetting()
                    }
                }
                .tint(DesignTokens.Colors.chatGPTGreen)
                .cardStyle()

                // Clear Data
                Button {
                    showClearConfirm = true
                } label: {
                    Label("Clear All Data", systemImage: "trash")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.errorRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                }
                .buttonStyle(.glass)
                .tint(DesignTokens.Colors.errorRed)

                // Version
                Text("ChatGPT Watch v1.0.0")
                    .font(DesignTokens.Typography.micro)
                    .foregroundStyle(.tertiary)
                    .padding(.top, DesignTokens.Spacing.sm)
            }
            .padding(.horizontal, DesignTokens.Spacing.xs)
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showAPIKey) {
            APIKeyInputView(apiKey: $apiKeyInput) {
                appState.settingsVM.apiKey = apiKeyInput
                appState.settingsVM.saveAPIKey()
                appState.authService.loginWithAPIKey(apiKeyInput)
                showAPIKey = false
            }
        }
        .confirmationDialog("Clear all data?", isPresented: $showClearConfirm) {
            Button("Clear All", role: .destructive) {
                appState.settingsVM.clearAllData()
            }
        }
        .onAppear { appState.settingsVM.loadSettings() }
    }
}

struct APIKeyInputView: View {
    @Binding var apiKey: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "key.fill")
                .font(.title2)
                .foregroundStyle(DesignTokens.Colors.chatGPTGreen)

            Text("API Key")
                .font(DesignTokens.Typography.sectionHeader)

            TextField("sk-...", text: $apiKey)
                .font(DesignTokens.Typography.code)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            HStack(spacing: DesignTokens.Spacing.sm) {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.glass)

                Button("Save") { onSave() }
                    .buttonStyle(.glassProminent)
                    .tint(DesignTokens.Colors.chatGPTGreen)
                    .disabled(apiKey.trimmed.isEmpty)
            }
        }
        .padding()
    }
}
