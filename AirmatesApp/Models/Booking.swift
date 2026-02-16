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

    // Relationships
    var aircraft: Aircraft?
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

struct BookingMember: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var email: String?
    var phone: String?
}
