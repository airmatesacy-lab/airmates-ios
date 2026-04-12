import Foundation

struct ClubEvent: Codable, Identifiable, Hashable {
    let id: String
    var title: String
    var description: String?
    var location: String?
    var startDate: String?
    var endDate: String?
    var allDay: Bool?
    var category: String?
    var imageUrl: String?
    var videoUrl: String?
    var createdById: String?
    var createdAt: String?
    var organizationId: String?

    // Relationships
    var createdBy: BookingMember?
    var rsvps: [EventRSVP]?
    var rsvpCount: Int?
}

struct EventRSVP: Codable, Identifiable, Hashable {
    let id: String
    var eventId: String?
    var memberId: String?
    var status: String? // ATTENDING, MAYBE, DECLINED
    var member: BookingMember?
}
