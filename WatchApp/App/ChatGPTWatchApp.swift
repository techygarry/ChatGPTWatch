import SwiftUI
import SwiftData

@main
struct ChatGPTWatchApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .modelContainer(for: [SDConversation.self, SDMessage.self, SDCodexSession.self])
    }
}
