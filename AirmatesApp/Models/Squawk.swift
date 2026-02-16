import Foundation

struct Squawk: Codable, Identifiable, Hashable {
    let id: String
    var aircraftId: String
    var reporterId: String
    var description: String
    var category: String
    var priority: String
    var status: String // OPEN, IN_PROGRESS, RESOLVED
    var resolution: String?
    var resolvedAt: String?
    var resolvedById: String?
    var resolvedByName: String?
    var createdAt: String?

    // Relationships
    var reporter: SquawkReporter?
    var aircraft: SquawkAircraft?
}

struct SquawkReporter: Codable, Hashable {
    var name: String
}

struct SquawkAircraft: Codable, Hashable {
    var tailNumber: String
}
