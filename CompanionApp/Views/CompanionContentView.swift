import SwiftUI

struct CompanionContentView: View {
    @Environment(CompanionConnectivityService.self) private var connectivity
    @State private var apiKey: String = ""
    @State private var showSavedAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "brain.head.profile.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color(red: 0.063, green: 0.639, blue: 0.498))

                        Text("ChatGPT Watch")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("ChatGPT on your wrist")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    // Watch Connection Status
                    HStack {
                        Image(systemName: connectivity.isWatchReachable ? "applewatch.radiowaves.left.and.right" : "applewatch.slash")
                            .font(.title2)
                            .foregroundStyle(connectivity.isWatchReachable ? .green : .secondary)

                        VStack(alignment: .leading) {
                            Text(connectivity.isWatchReachable ? "Watch Connected" : "Watch Not Reachable")
                                .font(.headline)
                            if let lastSync = connectivity.lastSyncDate {
                                Text("Last sync: \(lastSync.formatted(.relative(presentation: .named)))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // ChatGPT Subscription Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("ChatGPT Subscription", systemImage: "person.crop.circle.badge.checkmark")
                            .font(.headline)

                        Text("Connect your ChatGPT Plus or Pro subscription. Get your API key from platform.openai.com — it's included with your subscription.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        SecureField("sk-...", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.system(.body, design: .monospaced))

                        HStack {
                            if KeychainService.shared.load(key: KeychainKeys.openAIAPIKey) != nil {
                                Label("Key saved locally", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }

                            Spacer()

                            Button("Save & Sync") {
                                saveAPIKey()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(red: 0.063, green: 0.639, blue: 0.498))
                            .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Features Info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.headline)

                        FeatureRow(icon: "bubble.left.and.bubble.right.fill", title: "ChatGPT", description: "Full conversations with GPT-4o, o1, o3-mini", color: Color(red: 0.063, green: 0.639, blue: 0.498))

                        FeatureRow(icon: "chevron.left.forwardslash.chevron.right", title: "Codex", description: "Create and manage coding tasks remotely", color: Color(red: 0.671, green: 0.408, blue: 1.0))

                        FeatureRow(icon: "mic.fill", title: "Voice Input", description: "Dictate messages hands-free", color: .blue)

                        FeatureRow(icon: "bolt.fill", title: "Streaming", description: "Real-time response streaming", color: .orange)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Saved", isPresented: $showSavedAlert) {
                Button("OK") {}
            } message: {
                Text("API key saved and synced to your Apple Watch.")
            }
            .onAppear {
                apiKey = KeychainService.shared.load(key: KeychainKeys.openAIAPIKey) ?? ""
            }
        }
    }

    private func saveAPIKey() {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        KeychainService.shared.save(key: KeychainKeys.openAIAPIKey, value: key)
        connectivity.sendAPIKey(key)
        showSavedAlert = true
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
