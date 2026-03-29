import Foundation
import Observation

@Observable
@MainActor
final class AuthService {
    var isAuthenticated = false
    var userEmail: String?
    var isLoading = false
    var errorMessage: String?

    // Embedded key — auto-provisions on first launch
    // Paste your OpenAI API key here, or enter it in Settings on the watch
    private static let embeddedKey = ""

    init() {
        // Auto-provision embedded key into Keychain on first launch
        let existing = KeychainService.shared.load(key: KeychainKeys.openAIAPIKey)
        if existing == nil || existing?.isEmpty == true {
            KeychainService.shared.save(key: KeychainKeys.openAIAPIKey, value: Self.embeddedKey)
        }
        if let token = KeychainService.shared.load(key: KeychainKeys.openAIAPIKey), !token.isEmpty {
            isAuthenticated = true
        }
        userEmail = UserDefaults(suiteName: AppGroupConstants.suiteName)?.string(forKey: "userEmail")
    }
    
    func loginWithAPIKey(_ key: String) {
        KeychainService.shared.save(key: KeychainKeys.openAIAPIKey, value: key)
        isAuthenticated = true
    }
    
    func validateToken() async -> Bool {
        guard let token = KeychainService.shared.load(key: KeychainKeys.openAIAPIKey),
              !token.isEmpty else {
            isAuthenticated = false
            return false
        }
        
        isLoading = true
        defer { isLoading = false }
        
        var request = URLRequest(url: URL(string: "\(AppConstants.openAIBaseURL)/models")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 200 {
                    isAuthenticated = true
                    errorMessage = nil
                    return true
                } else if http.statusCode == 401 {
                    errorMessage = "Token expired. Please sign in again."
                    isAuthenticated = false
                    return false
                }
            }
        } catch {
            // Network error — assume token still valid (offline mode)
            return isAuthenticated
        }
        return false
    }
    
    func signOut() {
        KeychainService.shared.delete(key: KeychainKeys.openAIAPIKey)
        isAuthenticated = false
        userEmail = nil
        errorMessage = nil
        UserDefaults(suiteName: AppGroupConstants.suiteName)?.removeObject(forKey: "userEmail")
    }
}
