import Foundation

struct Flight: Codable, Identifiable, Hashable {
    let id: String
    var aircraftId: String?
    var memberId: String?
    var checkoutId: String?
    var instructorId: String?
    var date: String
    var tachOut: Double?
    var tachIn: Double?
    var tachTime: Double?
    var meterType: String?
    var type: String?
    var amount: Double?
    var notes: String?
    var billed: Bool?
    // flightTrack is raw JSON (ADS-B array) — skip decoding
    // var flightTrack: ignored
    var createdAt: String?
    var organizationId: String?

    // Landing counters
    var dayLandings: Int?
    var nightLandings: Int?
    var fullStopDay: Int?
    var fullStopNight: Int?
    var instrumentApproaches: Int?
    var holds: Int?

    // Relationships
    var aircraft: FlightAircraft?
    var member: BookingMember?
    var instructor: Instructor?
    var checkout: FlightCheckout?

    // Computed — meter-agnostic flight time (tach or hobbs depending on club setting)
    var flightTime: Double { tachTime ?? 0 }
    // Keep for backward compat with existing views
    var hobbsTime: Double { tachTime ?? 0 }
}

struct FlightAircraft: Codable, Hashable {
    var tailNumber: String?
    var type: String?
    var hourlyRate: Double?
}

struct FlightCheckout: Codable, Hashable {
    var checkOutTime: String?
    var checkInTime: String?
    var destination: String?
    var notes: String?
    var fuelAdded: Double?
}

// Flight uses CodingKeys to skip flightTrack (arbitrary JSON that can't be statically typed)
extension Flight {
    enum CodingKeys: String, CodingKey {
        case id, aircraftId, memberId, checkoutId, instructorId, date
        case tachOut, tachIn, tachTime, meterType, type, amount, notes, billed
        case createdAt, organizationId
        case dayLandings, nightLandings, fullStopDay, fullStopNight
        case instrumentApproaches, holds
        case aircraft, member, instructor, checkout
    }
}
