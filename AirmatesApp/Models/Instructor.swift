import Foundation

struct Instructor: Codable, Identifiable, Hashable {
    let id: String
    var userId: String
    var hourlyRate: Double?
    var specialties: String?
    var available: Bool

    // Relationships
    var user: InstructorUser?
    var schedule: [InstructorSchedule]?
    var bookings: [Booking]?
}

struct InstructorUser: Codable, Hashable {
    var id: String?
    var name: String
    var email: String?
    var phone: String?
    var image: String?
    var ratings: [String]?
}

struct InstructorSchedule: Codable, Identifiable, Hashable {
    let id: String
    var instructorId: String
    var dayOfWeek: Int
    var startTime: String
    var endTime: String
    var available: Bool
    var notes: String?
}
