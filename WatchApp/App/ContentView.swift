import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var isAuthenticated = false

    var body: some View {
        Group {
            if isAuthenticated {
                NavigationStack {
                    HomeView()
                }
            } else {
                LoginView()
            }
        }
        .onAppear {
            appState.initialize(modelContext: modelContext)
            isAuthenticated = appState.authService.isAuthenticated
        }
        .onChange(of: appState.authService.isAuthenticated) { _, newValue in
            withAnimation(DesignTokens.Animation.standard) {
                isAuthenticated = newValue
            }
        }
    }
}

// MARK: - Home Screen

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var appear = false

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Logo
                VStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "brain.head.profile.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                        .scaleEffect(appear ? 1.0 : 0.5)
                        .opacity(appear ? 1 : 0)

                    Text("ChatGPT")
                        .font(DesignTokens.Typography.largeTitle)
                }
                .padding(.top, DesignTokens.Spacing.sm)

                // Chat Card
                NavigationLink {
                    ConversationsListView()
                } label: {
                    HomeCard(
                        icon: "bubble.left.and.bubble.right.fill",
                        title: "Chat",
                        subtitle: chatSubtitle,
                        tint: DesignTokens.Colors.chatGPTGreen
                    )
                }
                .buttonStyle(.plain)

                // Codex Card
                NavigationLink {
                    CodexSessionsView()
                } label: {
                    HomeCard(
                        icon: "chevron.left.forwardslash.chevron.right",
                        title: "Codex",
                        subtitle: codexSubtitle,
                        tint: DesignTokens.Colors.codexPurple
                    )
                }
                .buttonStyle(.plain)

                // Settings
                NavigationLink {
                    SettingsView()
                } label: {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Text("Settings")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .glassEffect(.regular, in: .capsule)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignTokens.Spacing.xs)
        }
        .navigationTitle("Home")
        .onAppear {
            appState.chatVM.loadConversations(context: modelContext)
            withAnimation(DesignTokens.Animation.bouncy.delay(0.1)) {
                appear = true
            }
        }
    }

    private var chatSubtitle: String {
        let count = appState.chatVM.conversations.count
        if count == 0 { return "Start a conversation" }
        return "\(count) conversation\(count == 1 ? "" : "s")"
    }

    private var codexSubtitle: String {
        let count = appState.codexVM.sessions.count
        if count == 0 { return "Run coding tasks" }
        return "\(count) session\(count == 1 ? "" : "s")"
    }
}

// MARK: - Home Card

struct HomeCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(title)
                    .font(DesignTokens.Typography.sectionHeader)
                Text(subtitle)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(DesignTokens.Spacing.md)
        .glassEffect(.regular.tint(tint), in: .rect(cornerRadius: DesignTokens.Radius.medium))
    }
}
