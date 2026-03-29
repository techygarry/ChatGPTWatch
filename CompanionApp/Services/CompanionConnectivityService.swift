import Foundation
import WatchConnectivity
import Observation

@Observable
final class CompanionConnectivityService: NSObject, @unchecked Sendable {
    static let shared = CompanionConnectivityService()

    var isWatchReachable = false
    var lastSyncDate: Date?

    private var session: WCSession?

    private override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    func sendAPIKey(_ key: String) {
        guard let session, session.isReachable else {
            // Use application context as fallback
            try? session?.updateApplicationContext([
                WatchMessage.apiKeyField: key,
                "timestamp": Date().timeIntervalSince1970
            ])
            return
        }

        session.sendMessage([
            WatchMessage.apiKeyUpdate: true,
            WatchMessage.apiKeyField: key
        ], replyHandler: nil)

        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")
    }

    func sendSettings(_ settings: [String: Any]) {
        guard let session else { return }

        var payload = settings
        payload[WatchMessage.settingsSync] = true

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil)
        } else {
            try? session.updateApplicationContext(payload)
        }
    }
}

extension CompanionConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let reachable = session.isReachable
        Task { @MainActor in
            self.isWatchReachable = reachable
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in
            self.isWatchReachable = reachable
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // Handle messages from watch if needed
    }
}
