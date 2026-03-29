import SwiftUI

struct NewCodexTaskView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var taskInput = ""
    @State private var instructions = ""
    @State private var selectedProject: ProjectDir = .techyProjects
    @State private var showInstructions = false
    @State private var navigateToDetail = false
    @FocusState private var isInputFocused: Bool

    enum ProjectDir: String, CaseIterable, Identifiable {
        case techyProjects = "/Users/adsol/Documents/techy-projects"
        case chatgptWatch = "/Users/adsol/Documents/techy-projects/ChatGPTWatch"
        case bizos = "/Users/adsol/Documents/techy-projects/bizos"
        case vakhramart = "/Users/adsol/Documents/techy-projects/vakhramart"
        case wheelboss = "/Users/adsol/Documents/techy-projects/wheelboss"
        case openlead = "/Users/adsol/Documents/techy-projects/openlead"
        case diemart = "/Users/adsol/Documents/techy-projects/diemart-website"
        case renewable = "/Users/adsol/Documents/techy-projects/renewable-masters-crm"

        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .techyProjects: "All Projects"
            case .chatgptWatch: "ChatGPT Watch"
            case .bizos: "BizOS"
            case .vakhramart: "Vakhramart"
            case .wheelboss: "Wheelboss"
            case .openlead: "OpenLead"
            case .diemart: "Die Mart"
            case .renewable: "Renewable Masters"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.md) {
                // Header
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 26))
                    .foregroundStyle(DesignTokens.Colors.codexPurple)

                // Project
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Label("Project", systemImage: "folder.fill")
                        .font(DesignTokens.Typography.micro)
                        .foregroundStyle(DesignTokens.Colors.codexPurple)
                    Picker("Project", selection: $selectedProject) {
                        ForEach(ProjectDir.allCases) { proj in
                            Text(proj.displayName).tag(proj)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                .cardStyle()

                // Task Input
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("What should Codex do?")
                        .font(DesignTokens.Typography.micro)
                        .foregroundStyle(.secondary)
                    TextField("e.g., Fix the login bug...", text: $taskInput, axis: .vertical)
                        .font(DesignTokens.Typography.body)
                        .focused($isInputFocused)
                        .lineLimit(2...6)
                }
                .cardStyle()

                // Instructions toggle
                Button {
                    withAnimation(DesignTokens.Animation.spring) {
                        showInstructions.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 9))
                        Text("Custom Instructions")
                            .font(DesignTokens.Typography.caption)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8))
                            .rotationEffect(.degrees(showInstructions ? 90 : 0))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                if showInstructions {
                    TextField("System instructions...", text: $instructions, axis: .vertical)
                        .font(DesignTokens.Typography.body)
                        .lineLimit(2...4)
                        .cardStyle()
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }

                // Templates
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Templates")
                        .font(DesignTokens.Typography.micro)
                        .foregroundStyle(.secondary)

                    ForEach(taskTemplates, id: \.title) { template in
                        Button { taskInput = template.prompt } label: {
                            HStack(spacing: DesignTokens.Spacing.sm) {
                                Image(systemName: template.icon)
                                    .font(.system(size: 10))
                                    .foregroundStyle(DesignTokens.Colors.codexPurple)
                                    .frame(width: 14)
                                Text(template.title)
                                    .font(DesignTokens.Typography.caption)
                                Spacer()
                            }
                            .padding(DesignTokens.Spacing.sm)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Submit
                Button {
                    submitTask()
                } label: {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        if appState.codexVM.isCreating {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "play.fill")
                                .font(.system(size: 11))
                        }
                        Text(appState.codexVM.isCreating ? "Creating..." : "Run Task")
                            .font(DesignTokens.Typography.bodyMedium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignTokens.Colors.codexPurple)
                .disabled(taskInput.trimmed.isEmpty || appState.codexVM.isCreating)

                if let error = appState.codexVM.errorMessage {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Label("Error", systemImage: "exclamationmark.circle.fill")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.errorRed)
                        Text(error)
                            .font(DesignTokens.Typography.micro)
                            .foregroundStyle(.secondary)
                    }
                    .cardStyle()
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xs)
        }
        .navigationTitle("New Task")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToDetail) {
            if let session = appState.codexVM.currentSession {
                CodexSessionDetailView(sessionId: session.id)
            }
        }
    }

    private func submitTask() {
        let input = taskInput.trimmed
        let instr = instructions.trimmed.isEmpty
            ? "You are an expert software engineer. Write clean, efficient code."
            : instructions.trimmed
        appState.codexVM.createTask(input: input, instructions: instr, workingDir: selectedProject.rawValue)

        Task {
            try? await Task.sleep(for: .seconds(1))
            await MainActor.run {
                if appState.codexVM.currentSession != nil {
                    navigateToDetail = true
                }
            }
        }
    }

    private var taskTemplates: [(title: String, icon: String, prompt: String)] {
        [
            ("Fix a bug", "ladybug.fill", "Fix the bug in "),
            ("Add a feature", "plus.rectangle.fill", "Add a new feature that "),
            ("Write tests", "checkmark.shield.fill", "Write unit tests for "),
            ("Refactor code", "arrow.triangle.2.circlepath", "Refactor the code in "),
            ("Code review", "eye.fill", "Review and improve ")
        ]
    }
}
