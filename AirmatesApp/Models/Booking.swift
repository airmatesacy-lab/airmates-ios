import Foundation

struct Booking: Codable, Identifiable, Hashable {
    let id: String
    var aircraftId: String
    var memberId: String
    var instructorId: String?
    var startDate: String
    var endDate: String
    var startTime: String
    var endTime: String
    var type: String // SOLO, DUAL, MAINTENANCE
    var status: String // PENDING, CONFIRMED, STANDBY, CANCELLED, COMPLETED
    var notes: String?
    var createdAt: String?

    // Relationships — use lightweight BookingAircraft instead of full Aircraft
    // because some endpoints (e.g. /api/instructors nested bookings) return
    // only a partial aircraft like { tailNumber } with no id/type, which
    // can't decode into the full Aircraft model's non-optional fields.
    var aircraft: BookingAircraft?
    var member: BookingMember?
    var instructor: Instructor?

    var isPending: Bool { status == "PENDING" }
    var isConfirmed: Bool { status == "CONFIRMED" }
    var isStandby: Bool { status == "STANDBY" }

    var formattedDateRange: String {
        let start = DateFormatter.apiDate.date(from: startDate)
        let formatted = start.map { DateFormatter.display.string(from: $0) } ?? startDate
        return "\(formatted) \(startTime)–\(endTime)"
    }
}

struct BookingMember: Codable, Hashable {
    var id: String?
    var name: String
    var email: String?
    var phone: String?
    var role: String?
}

/// Lightweight aircraft struct used for nested Booking.aircraft. Some
/// backend endpoints (e.g. /api/instructors) return a partial shape like
/// `{ tailNumber }` for nested aircraft, so every field here is optional.
/// For endpoints that return the full aircraft, all fields populate normally.
struct BookingAircraft: Codable, Hashable {
    var id: String?
    var tailNumber: String?
    var type: String?
    var bookingColor: String?
    var status: String?
}
