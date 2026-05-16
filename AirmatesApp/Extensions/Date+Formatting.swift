import Foundation

extension DateFormatter {
    static let iso8601WithFractionalSeconds: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        f.timeZone = TimeZone(identifier: "UTC")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    static let iso8601: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        f.timeZone = TimeZone(identifier: "UTC")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    static let apiDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        f.timeZone = TimeZone(identifier: "UTC")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    static let display: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static let shortDisplay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f
    }()

    static let fullDisplay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d, yyyy"
        return f
    }()

    /// "yyyy-MM-dd" in the device's local time zone — for day-keying bookings.
    static let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    /// "MMM d" (e.g. "May 15") — for compact multi-day schedule labels.
    static let monthDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()
}

extension String {
    func toDate() -> Date? {
        DateFormatter.iso8601WithFractionalSeconds.date(from: self)
            ?? DateFormatter.iso8601.date(from: self)
    }

    func toDisplayDate() -> String {
        guard let date = toDate() else { return self }
        return DateFormatter.display.string(from: date)
    }

    func toShortDate() -> String {
        guard let date = toDate() else { return self }
        return DateFormatter.shortDisplay.string(from: date)
    }
}

extension Double {
    var asCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: self)) ?? "$\(self)"
    }

    var asHours: String {
        String(format: "%.1fh", self)
    }
}

extension Date {
    /// Combines this date's calendar day with an "HH:mm" wall-clock time
    /// (interpreted in the device's time zone) into the UTC ISO-8601 string
    /// the bookings API expects.
    func bookingISO(atTime timeStr: String) -> String {
        let dateStr = DateFormatter.yyyyMMdd.string(from: self)
        let local = DateFormatter()
        local.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        local.timeZone = .current
        guard let combined = local.date(from: "\(dateStr)T\(timeStr):00") else {
            return "\(dateStr)T\(timeStr):00.000Z"
        }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return iso.string(from: combined)
    }
}
