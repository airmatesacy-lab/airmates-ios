import Foundation
import EventKit

/// Wraps EventKit for adding Airmates bookings to the user's Apple Calendar.
/// Follows the singleton pattern used by APIClient / AuthService / KeychainManager.
final class CalendarService {
    static let shared = CalendarService()

    let eventStore = EKEventStore()

    private init() {}

    enum CalendarError: LocalizedError {
        case accessDenied
        case accessRestricted
        case invalidBookingDates

        var errorDescription: String? {
            switch self {
            case .accessDenied:
                return "Airmates needs permission to add events to your Calendar. Enable it in Settings → Airmates → Calendar."
            case .accessRestricted:
                return "Calendar access is restricted on this device."
            case .invalidBookingDates:
                return "Couldn't parse this booking's dates. Try again from the web."
            }
        }
    }

    /// Current authorization status for calendar writes.
    var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    /// Request calendar access. On iOS 17+ this uses requestFullAccessToEvents;
    /// on older iOS falls back to requestAccess(to:). Returns true if granted.
    @MainActor
    func requestAccess() async throws -> Bool {
        switch authorizationStatus {
        case .authorized, .fullAccess, .writeOnly:
            return true
        case .denied:
            throw CalendarError.accessDenied
        case .restricted:
            throw CalendarError.accessRestricted
        case .notDetermined:
            break
        @unknown default:
            break
        }

        if #available(iOS 17.0, *) {
            return try await eventStore.requestFullAccessToEvents()
        } else {
            return try await eventStore.requestAccess(to: .event)
        }
    }

    /// Build an EKEvent from an Airmates booking. Does NOT save — the caller
    /// typically presents EKEventEditViewController so the user can review
    /// and pick which calendar before saving.
    func makeEvent(from booking: Booking, currentUserName: String?) -> EKEvent? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoNoFrac = ISO8601DateFormatter()
        isoNoFrac.formatOptions = [.withInternetDateTime]

        // startDate/endDate from backend are UTC ISO 8601; try both with
        // and without fractional seconds
        guard
            let start = iso.date(from: booking.startDate) ?? isoNoFrac.date(from: booking.startDate),
            let end = iso.date(from: booking.endDate) ?? isoNoFrac.date(from: booking.endDate)
        else {
            return nil
        }

        let event = EKEvent(eventStore: eventStore)
        event.calendar = eventStore.defaultCalendarForNewEvents
        event.startDate = start
        event.endDate = end

        let tail = booking.aircraft?.tailNumber ?? "Aircraft"
        let typeLabel = booking.type.capitalized
        event.title = "Airmates: \(tail) \(typeLabel)"

        // Notes block
        var notes: [String] = []
        notes.append("Flight Type: \(typeLabel)")
        if let ac = booking.aircraft {
            notes.append("Aircraft: \(ac.tailNumber ?? "—") \(ac.type ?? "")")
        }
        if let memberName = booking.member?.name {
            notes.append("Pilot: \(memberName)")
        } else if let me = currentUserName {
            notes.append("Pilot: \(me)")
        }
        if let instructor = booking.instructor?.user?.name {
            notes.append("Instructor: \(instructor)")
        }
        if booking.isStandby {
            notes.append("Status: STANDBY")
        }
        if let userNotes = booking.notes, !userNotes.isEmpty {
            notes.append("")
            notes.append(userNotes)
        }
        event.notes = notes.joined(separator: "\n")

        // URL to the booking on the web
        event.url = URL(string: "https://airmatesacy.com")

        // 30-minute default reminder
        event.addAlarm(EKAlarm(relativeOffset: -30 * 60))

        return event
    }
}
