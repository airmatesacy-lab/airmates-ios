import SwiftUI

extension Color {
    static let brandBlue = Color(red: 37/255, green: 99/255, blue: 235/255) // #2563eb
    static let brandDark = Color(red: 26/255, green: 41/255, blue: 66/255) // #1a2942
    static let brandOrange = Color(red: 232/255, green: 145/255, blue: 58/255) // #e8913a
    static let brandGreen = Color(red: 34/255, green: 197/255, blue: 94/255)
    static let brandRed = Color(red: 239/255, green: 68/255, blue: 68/255)
    static let cardBackground = Color(.systemBackground)
    static let subtleBackground = Color(.secondarySystemBackground)

    // Booking calendar colors — matches web BOOKING_COLORS exactly
    static let bookingAmber = Color(red: 217/255, green: 119/255, blue: 6/255)    // #d97706 — my bookings
    static let bookingGray = Color(red: 156/255, green: 163/255, blue: 175/255)   // #9ca3af — cancelled
    static let bookingYellow = Color(red: 234/255, green: 179/255, blue: 8/255)   // #eab308 — standby
    static let bookingGreenFg = Color(red: 21/255, green: 128/255, blue: 61/255)  // #15803d — green aircraft
    static let bookingSlateFg = Color(red: 55/255, green: 65/255, blue: 81/255)   // #374151 — white aircraft
}

extension Color {
    static func statusColor(_ status: String) -> Color {
        switch status.uppercased() {
        case "AVAILABLE": return .brandGreen
        case "IN_FLIGHT": return .brandBlue
        case "MAINTENANCE": return .brandOrange
        case "CONFIRMED", "COMPLETED", "PAID": return .brandGreen
        case "PENDING": return .brandOrange
        case "STANDBY": return .purple
        case "CANCELLED", "FAILED", "OVERDUE": return .brandRed
        case "OUT": return .brandBlue
        case "OPEN": return .brandRed
        case "IN_PROGRESS": return .brandOrange
        case "RESOLVED": return .brandGreen
        default: return .secondary
        }
    }

    /// Calendar booking color — matches web bColor() priority exactly:
    /// 1. Status overrides (MISSED/CANCELLED/STANDBY)
    /// 2. MAINTENANCE type
    /// 3. User's own bookings → amber
    /// 4. Per-aircraft custom bookingColor
    /// 5. Aircraft type fallback (182=green, 172=gray, else=blue)
    static func bookingColor(
        type: String,
        status: String,
        aircraftType: String?,
        bookingColor: String?,
        isMine: Bool
    ) -> Color {
        // Status overrides
        switch status.uppercased() {
        case "MISSED": return .brandRed
        case "CANCELLED": return .bookingGray
        case "STANDBY": return .bookingYellow
        default: break
        }
        // Maintenance
        if type.uppercased() == "MAINTENANCE" { return .primary }
        // My bookings — warm amber
        if isMine { return .bookingAmber }
        // Per-aircraft custom color
        if let bc = bookingColor {
            return namedBookingColor(bc)
        }
        // Aircraft type fallback
        if let at = aircraftType {
            if at.contains("182") { return .bookingGreenFg }
            if at.contains("172") { return .bookingSlateFg }
        }
        return .brandBlue
    }

    /// Map web BOOKING_COLORS key names to SwiftUI colors
    private static func namedBookingColor(_ name: String) -> Color {
        switch name.lowercased() {
        case "blue":   return Color(red: 37/255, green: 99/255, blue: 235/255)
        case "green":  return Color(red: 21/255, green: 128/255, blue: 61/255)
        case "white":  return Color(red: 55/255, green: 65/255, blue: 81/255)
        case "purple": return Color(red: 124/255, green: 58/255, blue: 237/255)
        case "teal":   return Color(red: 13/255, green: 148/255, blue: 136/255)
        case "rose":   return Color(red: 225/255, green: 29/255, blue: 72/255)
        case "indigo": return Color(red: 79/255, green: 70/255, blue: 229/255)
        case "orange": return Color(red: 194/255, green: 65/255, blue: 12/255)
        case "slate":  return Color(red: 71/255, green: 85/255, blue: 105/255)
        default:       return Color(red: 37/255, green: 99/255, blue: 235/255) // blue default
        }
    }

    /// Booking type BADGE color (for the small type label) — matches web badge variants
    static func bookingTypeBadgeColor(_ type: String) -> Color {
        switch type.uppercased() {
        case "SOLO": return Color(red: 21/255, green: 128/255, blue: 61/255)         // success green #15803d
        case "DUAL": return Color(red: 29/255, green: 78/255, blue: 216/255)         // info blue #1d4ed8
        case "MAINTENANCE": return Color(red: 51/255, green: 65/255, blue: 85/255)   // default slate #334155
        default: return .brandBlue
        }
    }
}
