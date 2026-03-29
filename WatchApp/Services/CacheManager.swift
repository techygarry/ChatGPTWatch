import Foundation

final class CacheManager: @unchecked Sendable {
    static let shared = CacheManager()

    private let defaults: UserDefaults
    private let cacheKey = "response_cache"
    private let maxItems = 50

    private init() {
        defaults = UserDefaults(suiteName: AppGroupConstants.suiteName) ?? .standard
    }

    func cacheResponse(query: String, response: String) {
        var cache = loadCache()
        let key = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        cache[key] = CachedResponse(response: response, timestamp: Date())

        // Trim to max items (keep most recent)
        if cache.count > maxItems {
            let sorted = cache.sorted { $0.value.timestamp > $1.value.timestamp }
            cache = Dictionary(uniqueKeysWithValues: Array(sorted.prefix(maxItems)))
        }

        if let data = try? JSONEncoder().encode(cache) {
            defaults.set(data, forKey: cacheKey)
        }
    }

    func getCachedResponse(query: String) -> String? {
        let cache = loadCache()
        let key = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return cache[key]?.response
    }

    private func loadCache() -> [String: CachedResponse] {
        guard let data = defaults.data(forKey: cacheKey),
              let cache = try? JSONDecoder().decode([String: CachedResponse].self, from: data) else {
            return [:]
        }
        return cache
    }
}

private struct CachedResponse: Codable, Sendable {
    let response: String
    let timestamp: Date
}
