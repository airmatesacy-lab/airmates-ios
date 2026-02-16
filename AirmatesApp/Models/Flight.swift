import Foundation

struct Flight: Codable, Identifiable, Hashable {
    let id: String
    var aircraftId: String
    var memberId: String
    var checkoutId: String?
    var instructorId: String?
    var date: String
    var tachOut: Double
    var tachIn: Double
    var hobbsTime: Double
    var type: String
    var amount: Double
    var notes: String?
    var billed: Bool?

    // Relationships
    var aircraft: FlightAircraft?
    var member: BookingMember?
    var instructor: Instructor?
}

struct FlightAircraft: Codable, Hashable {
    var tailNumber: String
    var type: String
}
