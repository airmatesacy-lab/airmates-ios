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

    /// The booking's date, or a date range when it spans more than one day.
    /// e.g. "May 15, 2026" — or "May 15, 2026 – May 17, 2026".
    var formattedDateRange: String {
        guard let start = startDate.toDate() else {
            return startDate
        }
        let startText = DateFormatter.display.string(from: start)
        guard
            let end = endDate.toDate(),
            !Calendar.current.isDate(start, inSameDayAs: end)
        else {
            return startText
        }
        return "\(startText) \u{2013} \(DateFormatter.display.string(from: end))"
    }

    /// Date plus the start/end times, for compact contexts that have no
    /// separate time row (e.g. the Today tab's Next Flight card).
    var formattedDateTime: String {
        "\(formattedDateRange) \(startTime)\u{2013}\(endTime)"
    }

    /// Every calendar day (device-local, "yyyy-MM-dd") the booking occupies,
    /// inclusive of the start and end day. A single-day booking yields one
    /// entry; a multi-day booking yields one per day it spans. Empty if the
    /// dates can't be parsed.
    var coveredDayStrings: [String] {
        guard let start = startDate.toDate(), let end = endDate.toDate() else {
            return []
        }
        let calendar = Calendar.current
        var day = calendar.startOfDay(for: start)
        let lastDay = calendar.startOfDay(for: end)
        guard day <= lastDay else { return [] }
        var days: [String] = []
        while day <= lastDay {
            days.append(DateFormatter.yyyyMMdd.string(from: day))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return days
    }

    /// Compact start→end label for schedule rows. A single-day booking shows
    /// just the times ("09:30 – 10:00"); a multi-day booking includes the
    /// dates ("May 15 09:30 – May 17 10:00").
    var scheduleTimeLabel: String {
        guard
            let start = startDate.toDate(),
            let end = endDate.toDate(),
            !Calendar.current.isDate(start, inSameDayAs: end)
        else {
            return "\(startTime) \u{2013} \(endTime)"
        }
        let startDay = DateFormatter.monthDay.string(from: start)
        let endDay = DateFormatter.monthDay.string(from: end)
        return "\(startDay) \(startTime) \u{2013} \(endDay) \(endTime)"
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
