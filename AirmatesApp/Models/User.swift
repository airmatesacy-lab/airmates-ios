import Foundation

struct User: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var email: String
    var image: String?
    var role: String
    var phone: String?
    var active: Bool?
    var tierName: String?
    var tierId: String?

    // Profile fields
    var addressLine1: String?
    var addressLine2: String?
    var city: String?
    var state: String?
    var zip: String?
    var emergencyName: String?
    var emergencyPhone: String?
    var emergencyRelation: String?
    var pilotCertNumber: String?
    var ratings: [String]?
    var medicalClass: String?
    var medicalExpiry: String?
    var flightReviewDate: String?
    var flightReviewExpiry: String?
    var lastPassengerFlight: String?
    var lastNightFlight: String?
    var lastIFRActivity: String?
    var totalHours: Double?
    var joinedAt: String?
    var stripeCustomerId: String?
    var autoPayEnabled: Bool?
    var defaultPaymentMethodId: String?

    // Pilot certification
    var pilotCertType: String?

    // SIDA badge
    var sidaBadgeNumber: String?
    var sidaBadgeExpiry: String?
    var sidaBadgeIssued: String?

    // Knowledge test
    var knowledgeTestType: String?
    var knowledgeTestDate: String?
    var knowledgeTestScore: Int?
    var knowledgeTestExpiry: String?

    // Weather minimums
    var wxMinCeiling: Int?
    var wxMinVisibility: Double?
    var wxMaxWind: Int?
    var wxMaxCrosswind: Int?

    // Preferences
    var trackFlights: Bool?
    var smsOptIn: Bool?

    // Org context (from JWT)
    var organizationId: String?
    var orgSlug: String?
    var orgFeatures: [String]?
    var memberships: [OrgMembership]?

    // Relationships
    var membershipTier: MembershipTier?
    var instructorProfile: InstructorProfile?

    var isAdmin: Bool { role == "ADMIN" }
    var isInstructor: Bool { role == "INSTRUCTOR" }
    var hasMultipleOrgs: Bool { (memberships?.count ?? 0) > 1 }
}

struct OrgMembership: Codable, Identifiable, Hashable {
    let id: String
    var organizationId: String?
    var orgName: String?
    var orgSlug: String?
    var role: String?
    var active: Bool?
}

struct MembershipTier: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var monthlyDues: Double
    var freeHoursPerMonth: Double
    var maxActiveBookings: Int
    var maxBookingDaysOut: Int
    var description: String?
}

struct InstructorProfile: Codable, Identifiable, Hashable {
    let id: String
    var hourlyRate: Double?
    var specialties: String?
    var available: Bool
}
