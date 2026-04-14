import Foundation

class CacheService {
    static let shared = CacheService()
    private let fileManager = FileManager.default
    private let cacheDir: URL

    private init() {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDir = docs.appendingPathComponent(AppConstants.cacheDirectory)
        try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    // MARK: - Generic Cache

    func save<T: Codable>(_ value: T, key: String) {
        let url = cacheDir.appendingPathComponent("\(key).json")
        let wrapper = CacheWrapper(data: value, cachedAt: Date())
        if let data = try? JSONEncoder().encode(wrapper) {
            try? data.write(to: url)
        }
    }

    func load<T: Codable>(_ type: T.Type, key: String, maxAge: TimeInterval = AppConstants.cacheMaxAge) -> CachedResult<T>? {
        let url = cacheDir.appendingPathComponent("\(key).json")
        guard let data = try? Data(contentsOf: url),
              let wrapper = try? JSONDecoder().decode(CacheWrapper<T>.self, from: data)
        else { return nil }

        let age = Date().timeIntervalSince(wrapper.cachedAt)
        if age > maxAge { return nil }

        return CachedResult(data: wrapper.data, cachedAt: wrapper.cachedAt, age: age)
    }

    func clear(key: String) {
        let url = cacheDir.appendingPathComponent("\(key).json")
        try? fileManager.removeItem(at: url)
    }

    func clearAll() {
        try? fileManager.removeItem(at: cacheDir)
        try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    // MARK: - Convenience Keys

    static let fleetKey = "fleet"
    static let bookingsKey = "bookings"
    static let profileKey = "profile"
    static let weatherKey = "weather"
    static let announcementsKey = "announcements"
}

struct CacheWrapper<T: Codable>: Codable {
    let data: T
    let cachedAt: Date
}

struct CachedResult<T> {
    let data: T
    let cachedAt: Date
    let age: TimeInterval

    var formattedAge: String {
        let minutes = Int(age / 60)
        if minutes < 1 { return "Just now" }
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        return "\(hours / 24)d ago"
    }
}
