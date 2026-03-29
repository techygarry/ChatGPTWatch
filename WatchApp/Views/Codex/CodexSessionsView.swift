import SwiftUI
import SwiftData

struct CodexSessionsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var relayOnline = false
    @State private var checkingRelay = true

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.sm) {
                // Relay status
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Circle()
                        .fill(checkingRelay ? Color.gray : (relayOnline ? DesignTokens.Colors.successGreen : DesignTokens.Colors.errorRed))
                        .frame(width: 6, height: 6)
                    Text(checkingRelay ? "Checking..." : (relayOnline ? "Relay connected" : "Relay offline"))
                        .font(DesignTokens.Typography.micro)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if !checkingRelay {
                        Button {
                            checkRelay()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())

                if !relayOnline && !checkingRelay {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Label("Setup Required", systemImage: "exclamationmark.triangle.fill")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.warningAmber)

                        Text("Start relay on your Mac:")
                            .font(DesignTokens.Typography.micro)
                            .foregroundStyle(.secondary)

                        Text("cd codex-relay\nnode server.js")
                            .font(DesignTokens.Typography.code)
                            .foregroundStyle(DesignTokens.Colors.codexPurple)

                        Text("Then expose via Cloudflare Tunnel.")
                            .font(DesignTokens.Typography.micro)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(DesignTokens.Spacing.md)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous))
                }

                // New Task
                NavigationLink {
                    NewCodexTaskView()
                } label: {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(DesignTokens.Colors.codexPurple)
                        Text("New Task")
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(DesignTokens.Spacing.md)
                    .background(DesignTokens.Colors.codexPurple.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!relayOnline)
                .opacity(relayOnline ? 1.0 : 0.4)

                // Sessions
                if appState.codexVM.sessions.isEmpty && !appState.codexVM.isLoading && relayOnline {
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 28))
                            .foregroundStyle(DesignTokens.Colors.codexPurple.opacity(0.5))
                        Text("No Codex sessions")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(.secondary)
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

                if let error = appState.codexVM.errorMessage {
                    Text(error)
                        .font(DesignTokens.Typography.micro)
                        .foregroundStyle(DesignTokens.Colors.errorRed)
                        .padding(DesignTokens.Spacing.sm)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xs)
        }
        .navigationTitle("Codex")
        .onAppear {
            appState.codexVM.setModelContext(modelContext)
            checkRelay()
        }
    }

    private func checkRelay() {
        checkingRelay = true
        Task {
            let online = await appState.codexVM.codexService.checkRelayHealth()
            relayOnline = online
            checkingRelay = false
            if online {
                appState.codexVM.refreshSessions()
            }
        }
    }
}
