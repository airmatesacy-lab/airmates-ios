import Foundation

struct DashboardData: Codable {
    // Admin-only fields (nil for regular members)
    var aircraftCount: Int?
    var activeCheckouts: Int?
    var todayBookings: [Booking]?
    var unpaidTotal: Double?
    var memberCount: Int?
    var instructorCount: Int?
    var upcomingMaintenance: [MaintenanceItem]?
    var expiringMedicals: [ExpiringMedical]?
    var recentCheckouts: [Checkout]?

    // All users
    var myUpcomingBookings: [Booking]?
    var announcements: [Announcement]?
    var currency: CurrencyStatus?
    var onboardingComplete: Bool?
    var tourPending: Bool?
    var orgFeatures: [String]?
}

struct CurrencyStatus: Codable {
    var dayCurrentExpiry: String?
    var nightCurrentExpiry: String?
    var ifrCurrentExpiry: String?
    var medicalExpiry: String?
    var flightReviewExpiry: String?
}

struct ExpiringMedical: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var medicalExpiry: String?
    var medicalClass: String?
}
