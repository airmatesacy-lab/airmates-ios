import Foundation

struct Checkout: Codable, Identifiable, Hashable {
    let id: String
    var aircraftId: String
    var memberId: String
    var tachOut: Double
    var tachIn: Double?
    var checkOutTime: String
    var checkInTime: String?
    var meterType: String? // TACH, HOBBS
    var destination: String?
    var expectedReturn: String?
    var fuelAdded: Double?
    var status: String // OUT, COMPLETED
    var notes: String?
    var bookingId: String?
    var checkedInById: String?
    var lastOverdueAlertAt: String?
    var overdueAlertCount: Int?
    var organizationId: String?

    // Relationships
    var aircraft: Aircraft?
    var member: BookingMember?

    var isOut: Bool { status == "OUT" }

    var elapsedTime: TimeInterval? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let start = formatter.date(from: checkOutTime) else { return nil }
        return Date().timeIntervalSince(start)
    }

    var elapsedTimeFormatted: String {
        guard let elapsed = elapsedTime else { return "--" }
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

struct CheckoutResponse: Codable {
    var checkout: Checkout
    var flight: Flight?
}

struct CheckOutBody: Encodable {
    let aircraftId: String
    let tachOut: String
    let destination: String?
    let memberId: String? // admin/instructor checking out for someone else
}

struct CheckInBody: Encodable {
    let checkoutId: String
    let tachIn: String
    let fuelAdded: String?
    let flightType: String?
    let notes: String?
    let dayLandings: Int?
    let nightLandings: Int?
    let fullStopDay: Int?
    let fullStopNight: Int?
    let instrumentApproaches: Int?
    let holds: Int?
}
