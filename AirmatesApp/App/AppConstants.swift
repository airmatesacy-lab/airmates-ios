import Foundation

enum AppConstants {
    static let appVersion = "1.0"
    static let buildNumber = "1"

    // API
    static let baseURL = "https://airmatesacy.com"

    // Keychain keys
    static let tokenKey = "com.airmates.token"
    static let emailKey = "com.airmates.email"

    // Cache
    static let cacheDirectory = "AirmatesCache"
    static let cacheMaxAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days

    // Booking
    static let maxTachDeltaBeforeConfirmation: Double = 3.0
    static let tachMaxValue: Double = 99999.0

    // Time picker increments
    static let timeSlots: [String] = stride(from: 6, through: 20, by: 1).flatMap { hour in
        ["00", "30"].map { min in String(format: "%02d:%@", hour, min) }
    }

    // Flight types
    static let flightTypes = ["SOLO", "DUAL", "MAINTENANCE"]

    // Forum categories
    static let forumCategories = ["GENERAL", "SQUAWKS", "TRAINING", "MEETINGS", "SOCIAL", "COMMUNITY"]
}
