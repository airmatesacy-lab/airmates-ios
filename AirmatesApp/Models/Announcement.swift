import Foundation

struct Announcement: Codable, Identifiable, Hashable {
    let id: String
    var title: String
    var body: String
    var priority: String? // INFORMATIONAL, URGENT
    var requireConfirmation: Bool?
    var dismissed: Bool?
    var documentUrl: String?
    var documentName: String?
    var videoUrl: String?
    var requireSignature: Bool?
    var active: Bool?
    var expiresAt: String?
    var createdByName: String?
    var createdAt: String?
    var organizationId: String?

    var isUrgent: Bool { priority == "URGENT" }
}
