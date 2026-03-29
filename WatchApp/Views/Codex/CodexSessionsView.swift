import SwiftUI
import SwiftData

struct CodexSessionsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.sm) {
                // New Task
                NavigationLink {
                    NewCodexTaskView()
                } label: {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(DesignTokens.Colors.codexPurple)
                        Text("New Task")
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundStyle(DesignTokens.Colors.codexPurple)
                        Spacer()
                    }
                    .padding(DesignTokens.Spacing.md)
                    .glassEffect(.regular.tint(DesignTokens.Colors.codexPurple), in: .rect(cornerRadius: DesignTokens.Radius.medium))
                }
                .buttonStyle(.plain)

                if appState.codexVM.sessions.isEmpty && !appState.codexVM.isLoading {
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 28))
                            .foregroundStyle(DesignTokens.Colors.codexPurple.opacity(0.5))
                        Text("No Codex sessions")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(.secondary)
                        Text("Create a task to start coding")
                            .font(DesignTokens.Typography.timestamp)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.xl)
                } else {
                    ForEach(appState.codexVM.sessions) { session in
                        NavigationLink {
                            CodexSessionDetailView(sessionId: session.id)
                        } label: {
                            CodexTaskCard(session: session)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if appState.codexVM.isLoading {
                    ProgressView()
                        .tint(DesignTokens.Colors.codexPurple)
                        .padding()
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xs)
        }
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
