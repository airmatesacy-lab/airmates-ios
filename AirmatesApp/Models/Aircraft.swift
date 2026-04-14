import Foundation

struct Aircraft: Codable, Identifiable, Hashable {
    let id: String
    var tailNumber: String
    var type: String
    var year: Int?
    var hourlyRate: Double?
    var tachCurrent: Double?
    var hobbsCurrent: Double?
    var meterType: String? // TACH, HOBBS
    var status: String?
    var imageColor: String?
    var bookingColor: String?
    var imageUrl: String?
    var notes: String?
    var icaoHex: String?
    var organizationId: String?

    // Inspection
    var annualInspectionDate: String?
    var hundredHourInspectionTach: Double?
    var nextAnnualDue: String?
    var nextHundredHourDue: Double?

    // ADS-B
    var flightAwareAlertId: String?
    var lastOpenSkyState: String?
    var lastOpenSkyTs: String?

    // Relationships (optional, included when requested)
    var maintenance: [MaintenanceItem]?
    var documents: [AircraftDocument]?
    var squawks: [Squawk]?
    var checkouts: [Checkout]?
    var flights: [Flight]?
    var notices: [AircraftNotice]?

    var isAvailable: Bool { status == "AVAILABLE" }
    var isInFlight: Bool { status == "IN_FLIGHT" }
    var isInMaintenance: Bool { status == "MAINTENANCE" || status == "GROUNDED" }
}

struct MaintenanceItem: Codable, Identifiable, Hashable {
    let id: String
    var type: String?
    var category: String?
    var description: String?
    var dueDate: String?
    var dueTach: Double?
    var completed: Bool?
    var completedDate: String?
    var completedBy: String?
    var regulatory: Bool?
    var intervalMonths: Int?
    var intervalHours: Double?
    var aircraftId: String?
    var organizationId: String?
}

struct AircraftDocument: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var expires: String?
    var fileUrl: String?
    var aircraftId: String
}
