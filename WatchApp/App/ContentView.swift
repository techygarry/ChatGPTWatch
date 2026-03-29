import SwiftUI
import SwiftData

enum ContentTab: Int, CaseIterable {
    case chat
    case codex
    case settings

    var label: String {
        switch self {
        case .chat: "Chat"
        case .codex: "Codex"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .chat: "bubble.left.and.bubble.right.fill"
        case .codex: "chevron.left.forwardslash.chevron.right"
        case .settings: "gearshape.fill"
        }
    }
}

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: ContentTab = .chat
    @State private var isAuthenticated = false

    var body: some View {
        Group {
            if isAuthenticated {
                MainTabView()
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

struct MainTabView: View {
    @State private var selectedTab: ContentTab = .chat

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ConversationsListView()
            }
            .tag(ContentTab.chat)

            NavigationStack {
                CodexSessionsView()
            }
            .tag(ContentTab.codex)

            NavigationStack {
                SettingsView()
            }
            .tag(ContentTab.settings)
        }
        .tabViewStyle(.verticalPage)
    }
}
