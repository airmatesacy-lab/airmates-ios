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
    /// Linked booking (id + type). Backend populates this via the auto-link at
    /// check-out time and returns it in GET/POST /api/checkouts responses.
    /// Optional because older backends and unmatched checkouts return null.
    /// The iOS app uses this to preload the flight type picker on check-in
    /// so members don't have to re-pick SOLO/DUAL/MAINTENANCE.
    var booking: LinkedBooking?

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

/// Minimal booking shape returned nested inside a Checkout. Matches the
/// backend's `include: { booking: { select: { id: true, type: true } } }`.
struct LinkedBooking: Codable, Hashable {
    let id: String
    let type: String // SOLO | DUAL | MAINTENANCE
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
