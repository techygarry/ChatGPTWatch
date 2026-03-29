import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var currentPage = 0

    var body: some View {
        TabView(selection: $currentPage) {
            // Page 1: Home
            NavigationStack {
                HomeView()
            }
            .tag(0)

            // Page 2: Settings (horizontal swipe)
            NavigationStack {
                SettingsView()
            }
            .tag(1)
        }
        .tabViewStyle(.page)
        .onAppear {
            appState.initialize(modelContext: modelContext)
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
                // ChatGPT Logo
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Image("ChatGPTLogo")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                        .frame(width: 40, height: 40)
                        .scaleEffect(appear ? 1.0 : 0.5)
                        .opacity(appear ? 1 : 0)

                    Text("ChatGPT")
                        .font(DesignTokens.Typography.largeTitle)
                }
                .padding(.top, DesignTokens.Spacing.xs)

                // Chat
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

                // Codex
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

                // Swipe hint
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 8))
                    Text("Swipe for settings")
                        .font(DesignTokens.Typography.micro)
                }
                .foregroundStyle(.tertiary)
                .padding(.top, DesignTokens.Spacing.xs)
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
        return count == 0 ? "Start a conversation" : "\(count) conversation\(count == 1 ? "" : "s")"
    }

    private var codexSubtitle: String {
        let count = appState.codexVM.sessions.count
        return count == 0 ? "Run coding tasks" : "\(count) session\(count == 1 ? "" : "s")"
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
