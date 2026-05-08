import Foundation

enum DeepLink: Equatable {
    case preFlightReminder(orgId: String, aircraftId: String)
}
