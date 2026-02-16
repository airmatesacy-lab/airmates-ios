import SwiftUI

extension Color {
    static let brandBlue = Color(red: 37/255, green: 99/255, blue: 235/255) // #2563eb
    static let brandDark = Color(red: 26/255, green: 41/255, blue: 66/255) // #1a2942
    static let brandOrange = Color(red: 232/255, green: 145/255, blue: 58/255) // #e8913a
    static let brandGreen = Color(red: 34/255, green: 197/255, blue: 94/255)
    static let brandRed = Color(red: 239/255, green: 68/255, blue: 68/255)
    static let cardBackground = Color(.systemBackground)
    static let subtleBackground = Color(.secondarySystemBackground)
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
}
