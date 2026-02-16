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

    // Relationships
    var membershipTier: MembershipTier?
    var instructorProfile: InstructorProfile?

    var isAdmin: Bool { role == "ADMIN" }
    var isInstructor: Bool { role == "INSTRUCTOR" }
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
