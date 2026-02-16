import Foundation

struct DashboardData: Codable {
    var aircraftCount: Int
    var activeCheckouts: Int
    var todayBookings: [Booking]
    var unpaidTotal: Double?
    var memberCount: Int
    var instructorCount: Int
    var upcomingMaintenance: [MaintenanceItem]
    var expiringMedicals: [ExpiringMedical]
    var recentCheckouts: [Checkout]
    var myUpcomingBookings: [Booking]
}

struct ExpiringMedical: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var medicalExpiry: String?
    var medicalClass: String?
}
