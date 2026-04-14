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
    var replies: [ForumReply]?
    var _count: ForumPostCount?
    var replyCount: Int? { _count?.replies }

    // Reactions
    var reactions: [ForumReaction]?

    var isPinned: Bool { pinned == true }
    var isLocked: Bool { lockedAt != nil }
    var totalReplies: Int { _count?.replies ?? replies?.count ?? 0 }
}

struct ForumPostCount: Codable, Hashable {
    var replies: Int?
}

struct ForumReaction: Codable, Identifiable, Hashable {
    let id: String
    var emoji: String?
    var memberId: String?
    var member: BookingMember?
}
