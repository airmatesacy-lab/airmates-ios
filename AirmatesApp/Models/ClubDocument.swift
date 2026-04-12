import Foundation

struct ClubDocument: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var description: String?
    var category: String?
    var fileUrl: String?
    var fileSize: Int?
    var uploadedByName: String?
    var visibility: String?
    var createdAt: String?
    var organizationId: String?
}
