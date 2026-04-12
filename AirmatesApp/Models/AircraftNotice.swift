import Foundation

struct AircraftNotice: Codable, Identifiable, Hashable {
    let id: String
    var aircraftId: String
    var title: String
    var body: String
    var priority: String // INFO, WARNING, CRITICAL
    var blockCheckout: Bool?
    var blockBooking: Bool?
    var requireSignature: Bool?
    var documentUrl: String?
    var documentName: String?
    var videoUrl: String?
    var expiryType: String? // DATE, TACH
    var expiryDate: String?
    var expiryTach: Double?
    var version: Int?
    var active: Bool?
    var createdAt: String?
    var updatedAt: String?

    // Populated for member view
    var acked: Bool?
    var ackDate: String?
    var creator: NoticeCreator?

    var isBlocking: Bool { blockCheckout == true || blockBooking == true }
    var isCritical: Bool { priority == "CRITICAL" }
    var isWarning: Bool { priority == "WARNING" }
}

struct NoticeCreator: Codable, Hashable {
    let id: String
    var name: String?
}

struct NoticeAckRequest: Encodable {
    let noticeId: String
    let noticeVersion: Int
    let signedName: String?
}

struct NoticeBlockResponse: Decodable {
    let error: String
    let noticesRequired: Bool?
    let notices: [AircraftNotice]?
}
