import Foundation

struct StudentLesson: Codable, Identifiable, Hashable {
    let id: String
    var studentId: String?
    var instructorId: String?
    var lessonPlanId: String?
    var flightId: String?
    var date: String?
    var grade: String? // SATISFACTORY, UNSATISFACTORY, INCOMPLETE
    var notes: String?
    var preBriefNotes: String?
    var postBriefNotes: String?
    var completedObjectives: [String]?
    var durationHours: Double?
    var createdAt: String?

    // Relationships
    var student: BookingMember?
    var instructor: BookingMember?
    var flight: Flight?

    var isSatisfactory: Bool { grade == "SATISFACTORY" }
}
