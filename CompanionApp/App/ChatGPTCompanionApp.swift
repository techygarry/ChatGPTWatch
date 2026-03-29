import SwiftUI

@main
struct ChatGPTCompanionApp: App {
    @State private var connectivityService = CompanionConnectivityService.shared

    var body: some Scene {
        WindowGroup {
            CompanionContentView()
                .environment(connectivityService)
        }
    }
}
