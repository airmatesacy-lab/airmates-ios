import Foundation

@Observable
class EventsViewModel {
    var events: [ClubEvent] = []
    var isLoading = true
    var errorMessage: String?

    func fetchEvents() async {
        isLoading = events.isEmpty
        errorMessage = nil

        do {
            events = try await APIClient.shared.get("/api/events")
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func rsvp(eventId: String, status: String) async -> Bool {
        struct RSVPBody: Encodable { let eventId: String; let status: String }
        do {
            let _: ClubEvent = try await APIClient.shared.post(
                "/api/events",
                body: RSVPBody(eventId: eventId, status: status)
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
