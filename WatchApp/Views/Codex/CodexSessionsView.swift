import SwiftUI
import SwiftData

struct CodexSessionsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            // New Task
            NavigationLink {
                NewCodexTaskView()
            } label: {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(DesignTokens.Colors.codexPurple.opacity(0.15))
                            .frame(width: 28, height: 28)
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(DesignTokens.Colors.codexPurple)
                    }
                    Text("New Task")
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundStyle(DesignTokens.Colors.codexPurple)
                }
            }
            .listRowBackground(
                DesignTokens.Colors.surfaceMid
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
            )

            if appState.codexVM.sessions.isEmpty && !appState.codexVM.isLoading {
                VStack(spacing: DesignTokens.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(DesignTokens.Colors.codexPurple.opacity(0.08))
                            .frame(width: 56, height: 56)
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 24))
                            .foregroundStyle(DesignTokens.Colors.codexPurple.opacity(0.5))
                    }
                    Text("No Codex sessions")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                    Text("Create a task to start coding")
                        .font(DesignTokens.Typography.timestamp)
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.xl)
                .listRowBackground(Color.clear)
            } else {
                ForEach(appState.codexVM.sessions) { session in
                    NavigationLink {
                        CodexSessionDetailView(sessionId: session.id)
                    } label: {
                        CodexTaskCard(session: session)
                    }
                    .listRowBackground(
                        DesignTokens.Colors.surfaceMid
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
                    )
                }
            }

            if appState.codexVM.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(DesignTokens.Colors.codexPurple)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Codex")
        .refreshable {
            appState.codexVM.refreshSessions()
        }
        .onAppear {
            appState.codexVM.setModelContext(modelContext)
            if appState.codexVM.sessions.isEmpty {
                appState.codexVM.refreshSessions()
            }
        }
    }
}
