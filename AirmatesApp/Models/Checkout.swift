import Foundation

struct Checkout: Codable, Identifiable, Hashable {
    let id: String
    var aircraftId: String
    var memberId: String
    var tachOut: Double
    var tachIn: Double?
    var checkOutTime: String
    var checkInTime: String?
    var destination: String?
    var expectedReturn: String?
    var fuelAdded: Double?
    var status: String // OUT, COMPLETED
    var notes: String?

    // Relationships
    var aircraft: Aircraft?
    var member: BookingMember?

    var isOut: Bool { status == "OUT" }
}

struct CheckoutResponse: Codable {
    var checkout: Checkout
    var flight: Flight?
}
