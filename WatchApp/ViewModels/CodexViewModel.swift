import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class CodexViewModel {
    var sessions: [CodexSession] = []
    var currentSession: CodexSession?
    var isLoading = false
    var isCreating = false
    var relayConnected = false
    var errorMessage: String?

    let codexService: CodexService
    private var modelContext: ModelContext?
    private var pollingTask: Task<Void, Never>?

    init(codexService: CodexService) {
        self.codexService = codexService
    }

    // MARK: - Check relay connection
    func checkRelay() {
        Task {
            relayConnected = await codexService.checkRelayHealth()
        }
    }

    // MARK: - Create Task
    func createTask(input: String, instructions: String = "You are an expert software engineer. Write clean, production-ready code.", workingDir: String? = nil) {
        guard !input.trimmed.isEmpty else { return }
        isCreating = true
        errorMessage = nil

        Task {
            do {
                let session = try await codexService.createSession(input: input, instructions: instructions, workingDir: workingDir)
                sessions.insert(session, at: 0)
                currentSession = session
                isCreating = false
                HapticManager.shared.play(.taskCreated)
                // Poll for completion
                startPolling(sessionId: session.id)
            } catch {
                isCreating = false
                errorMessage = error.localizedDescription
                HapticManager.shared.play(.error)
            }
        }
    }

    // MARK: - Refresh from relay
    func refreshSessions() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let fetched = try await codexService.listSessions()
                sessions = fetched
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
                loadCachedSessions()
            }
        }
    }

    // MARK: - Load session
    func loadSession(id: String) {
        isLoading = true
        Task {
            do {
                let session = try await codexService.getSession(id: id)
                currentSession = session
                isLoading = false
                if let idx = sessions.firstIndex(where: { $0.id == id }) {
                    sessions[idx] = session
                }
                if !session.status.isTerminal {
                    startPolling(sessionId: id)
                }
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    // MARK: - Cancel
    func cancelTask(id: String) {
        Task {
            do {
                try await codexService.cancelSession(id: id)
                if let idx = sessions.firstIndex(where: { $0.id == id }) {
                    sessions[idx].status = .cancelled
                }
                if currentSession?.id == id {
                    currentSession?.status = .cancelled
                }
                stopPolling()
                HapticManager.shared.play(.tap)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func selectSession(_ session: CodexSession) {
        currentSession = session
        if !session.status.isTerminal {
            loadSession(id: session.id)
        }
    }

    // MARK: - Polling
    private func startPolling(sessionId: String) {
        stopPolling()
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(AppConstants.pollingInterval))
                if Task.isCancelled { break }

                do {
                    let session = try await codexService.getSession(id: sessionId)
                    currentSession = session
                    if let idx = sessions.firstIndex(where: { $0.id == sessionId }) {
                        sessions[idx] = session
                    }
                    if session.status.isTerminal {
                        if session.status == .completed {
                            HapticManager.shared.play(.taskComplete)
                        } else if session.status == .failed {
                            HapticManager.shared.play(.taskFailed)
                        }
                        cacheSession(session)
                        break
                    }
                } catch {
                    break
                }
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    // MARK: - Persistence
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    private func cacheSession(_ session: CodexSession) {
        guard let context = modelContext else { return }
        let sid = session.id
        let descriptor = FetchDescriptor<SDCodexSession>(predicate: #Predicate { $0.sessionId == sid })
        if (try? context.fetch(descriptor).first) != nil {
            // Already cached, skip
        } else {
            context.insert(SDCodexSession(session: session))
        }
        try? context.save()
    }

    private func loadCachedSessions() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<SDCodexSession>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        if let results = try? context.fetch(descriptor) {
            sessions = results.map { $0.toCodexSession() }
        }
    }
}
