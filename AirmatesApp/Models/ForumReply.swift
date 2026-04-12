import Foundation

struct ForumReply: Codable, Identifiable, Hashable {
    let id: String
    var postId: String
    var memberId: String?
    var parentReplyId: String?
    var content: String
    var createdAt: String?
    var attachments: [String]?

    // Relationships
    var member: BookingMember?
}
