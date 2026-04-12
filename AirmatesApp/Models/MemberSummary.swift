import Foundation

struct MemberSummary: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var email: String?
    var phone: String?
    var role: String? // ADMIN, INSTRUCTOR, PILOT_MEMBER
    var image: String?
    var active: Bool?
    var approved: Bool?
    var pilotCertType: String?
    var ratings: [String]?
    var totalHours: Double?
    var joinedAt: String?
    var membershipTier: TierSummary?

    var isAdmin: Bool { role == "ADMIN" }
    var isInstructor: Bool { role == "INSTRUCTOR" }
}

struct TierSummary: Codable, Hashable {
    var name: String?
    var monthlyDues: Double?
}
