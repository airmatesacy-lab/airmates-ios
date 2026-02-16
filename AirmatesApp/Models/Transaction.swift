import Foundation

struct Transaction: Codable, Identifiable, Hashable {
    let id: String
    var memberId: String
    var type: String // MONTHLY_DUES, FLIGHT_CHARGE, PAYMENT, CREDIT, etc.
    var amount: Double
    var description: String
    var status: String // PENDING, COMPLETED, PAID, OVERDUE
    var billingMonth: String?
    var stripePaymentIntentId: String?
    var createdAt: String?
    var createdBy: String?

    var isCharge: Bool {
        ["FLIGHT_CHARGE", "MONTHLY_DUES", "ASSESSMENT", "INSTRUCTION_FEE"].contains(type)
    }

    var isPayment: Bool {
        ["PAYMENT", "CREDIT", "FREE_HOURS_CREDIT"].contains(type)
    }
}
