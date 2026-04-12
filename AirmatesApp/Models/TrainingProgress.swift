import Foundation

struct TrainingProgress: Codable {
    var lessons: [StudentLesson]?
    var endorsements: [Endorsement]?
    var stageChecks: [StageCheck]?
    var checkrides: [Checkride]?
    var totalHours: Double?
    var completedObjectives: Int?
    var totalObjectives: Int?
}

struct Endorsement: Codable, Identifiable, Hashable {
    let id: String
    var studentId: String?
    var instructorId: String?
    var type: String?
    var description: String?
    var dateIssued: String?
    var createdAt: String?

    var instructor: BookingMember?
}

struct StageCheck: Codable, Identifiable, Hashable {
    let id: String
    var studentId: String?
    var instructorId: String?
    var stageName: String?
    var passed: Bool?
    var date: String?
    var notes: String?
    var createdAt: String?

    var instructor: BookingMember?
}

struct Checkride: Codable, Identifiable, Hashable {
    let id: String
    var studentId: String?
    var instructorId: String?
    var type: String?
    var passed: Bool?
    var date: String?
    var examinerName: String?
    var notes: String?
    var createdAt: String?
}
