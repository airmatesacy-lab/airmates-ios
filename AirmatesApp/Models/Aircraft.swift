import Foundation

struct Aircraft: Codable, Identifiable, Hashable {
    let id: String
    var tailNumber: String
    var type: String
    var year: Int?
    var hourlyRate: Double
    var tachCurrent: Double
    var status: String
    var image: String?
    var notes: String?

    // Relationships (optional, included when requested)
    var maintenance: [MaintenanceItem]?
    var documents: [AircraftDocument]?
    var squawks: [Squawk]?
    var checkouts: [Checkout]?
    var flights: [Flight]?

    var isAvailable: Bool { status == "AVAILABLE" }
    var isInFlight: Bool { status == "IN_FLIGHT" }
    var isInMaintenance: Bool { status == "MAINTENANCE" }
}

struct MaintenanceItem: Codable, Identifiable, Hashable {
    let id: String
    var type: String
    var description: String?
    var dueDate: String?
    var dueTach: Double?
    var completed: Bool
    var completedDate: String?
    var aircraft: Aircraft?
}

struct AircraftDocument: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var expires: String?
    var fileUrl: String?
    var aircraftId: String
}
