import SwiftUI

struct CodexSessionDetailView: View {
    @Environment(AppState.self) private var appState
    let sessionId: String

    private var session: CodexSession? {
        appState.codexVM.currentSession?.id == sessionId
            ? appState.codexVM.currentSession
            : appState.codexVM.sessions.first { $0.id == sessionId }
    }

    var body: some View {
        ScrollView {
            if let session {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    // Status
                    HStack {
                        StatusBadge(status: session.status)
                        Spacer()
                        Text(session.createdAt.relativeString)
                            .font(DesignTokens.Typography.timestamp)
                            .foregroundStyle(.tertiary)
                    }

                    // Task
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Label("Task", systemImage: "text.bubble.fill")
                            .font(DesignTokens.Typography.micro)
                            .foregroundStyle(DesignTokens.Colors.codexPurple)
                        Text(session.input)
                            .font(DesignTokens.Typography.body)
                    }
                    .cardStyle()

                    // Output
                    if !session.output.isEmpty {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            Label("Output", systemImage: "text.alignleft")
                                .font(DesignTokens.Typography.micro)
                                .foregroundStyle(DesignTokens.Colors.codexBlue)

                            ForEach(session.output) { item in
                                switch item.type {
                                case .message:
                                    Text(item.content)
                                        .font(DesignTokens.Typography.body)
                                case .code:
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        Text(item.content)
                                            .font(DesignTokens.Typography.code)
                                            .foregroundStyle(DesignTokens.Colors.chatGPTGreen)
                                            .padding(DesignTokens.Spacing.sm)
                                    }
                                    .background(.black.opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
                                case .fileChange:
                                    Text(item.content)
                                        .font(DesignTokens.Typography.code)
                                        .foregroundStyle(DesignTokens.Colors.warningAmber)
                                }
                            }
                        }
                        .cardStyle()
                    }

                    // Files Changed
                    if !session.filesChanged.isEmpty {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            Label("Files Changed", systemImage: "doc.on.doc.fill")
                                .font(DesignTokens.Typography.micro)
                                .foregroundStyle(DesignTokens.Colors.warningAmber)

                            ForEach(session.filesChanged) { file in
                                HStack(spacing: DesignTokens.Spacing.sm) {
                                    Image(systemName: file.action.symbol)
                                        .font(.caption2)
                                        .foregroundStyle(fileActionColor(file.action))
                                    Text(file.path)
                                        .font(DesignTokens.Typography.code)
                                        .lineLimit(1)
                                }

                                if let diff = file.diff {
                                    Text(diff)
                                        .font(DesignTokens.Typography.code)
                                        .foregroundStyle(.secondary)
                                        .padding(DesignTokens.Spacing.xs)
                                        .background(.black.opacity(0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
                                }
                            }
                        }
                        .cardStyle()
                    }

                    // Progress
                    if !session.status.isTerminal {
                        VStack(spacing: DesignTokens.Spacing.sm) {
                            ProgressView()
                                .tint(DesignTokens.Colors.codexPurple)
                            Text("Processing...")
                                .font(DesignTokens.Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .cardStyle()
                    }

                    // Actions
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        if !session.status.isTerminal {
                            Button("Cancel") {
                                appState.codexVM.cancelTask(id: sessionId)
                            }
                            .font(DesignTokens.Typography.micro)
                            .buttonStyle(.bordered)
                            .tint(DesignTokens.Colors.errorRed)
                        }

                        Button("Refresh") {
                            appState.codexVM.loadSession(id: sessionId)
                        }
                        .font(DesignTokens.Typography.micro)
                        .buttonStyle(.bordered)
                        .tint(DesignTokens.Colors.codexBlue)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xs)
            } else {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    ProgressView()
                        .tint(DesignTokens.Colors.codexPurple)
                    Text("Loading...")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, DesignTokens.Spacing.xl)
            }
        }
        .navigationTitle("Task")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { appState.codexVM.loadSession(id: sessionId) }
        .onDisappear { appState.codexVM.stopPolling() }
    }

    private func fileActionColor(_ action: FileAction) -> Color {
        switch action {
        case .created: DesignTokens.Colors.successGreen
        case .modified: DesignTokens.Colors.warningAmber
        case .deleted: DesignTokens.Colors.errorRed
        }
    }
}
