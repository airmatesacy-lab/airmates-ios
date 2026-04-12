import Foundation

struct ForumPost: Codable, Identifiable, Hashable {
    let id: String
    var memberId: String?
    var category: String? // GENERAL, SQUAWKS, TRAINING, MEETINGS, SOCIAL, COMMUNITY
    var title: String
    var content: String?
    var pinned: Bool?
    var viewCount: Int?
    var lastActivityAt: String?
    var createdAt: String?
    var lockedAt: String?
    var attachments: [String]?

    // Relationships
    var member: BookingMember?
    var replyCount: Int?

    var isPinned: Bool { pinned == true }
    var isLocked: Bool { lockedAt != nil }
}
