import Foundation

struct WeatherData: Codable {
    var icao: String?
    var metar: String?
    var parsed: ParsedMetar?
    var minimums: WeatherMinimums?
    var goNoGo: Bool?
    var issues: [String]?
    var hasMinimums: Bool?
}

struct WeatherMinimums: Codable {
    var wxMinCeiling: Int?
    var wxMinVisibility: Double?
    var wxMaxWind: Int?
    var wxMaxCrosswind: Int?
}

struct ParsedMetar: Codable {
    var ceiling: Double?
    var visibility: Double?
    var windSpeed: Double?
    var windDir: Double?       // API returns "windDir" not "windDirection"
    var gustSpeed: Double?
    var temp: Double?           // API returns "temp" not "temperature"
    var dewp: Double?           // API returns "dewp" not "dewpoint"
    var dewpoint: Double?       // Some responses use full name
    var altimeter: Double?
    var flightCategory: String? // VFR, MVFR, IFR, LIFR

    // Computed accessors with friendly names
    var temperature: Int? { temp != nil ? Int(temp!) : nil }
    var windDirection: Int? { windDir != nil ? Int(windDir!) : nil }

    var windDescription: String {
        guard let dir = windDir, let spd = windSpeed else { return "Calm" }
        if let gust = gustSpeed {
            return "\(Int(dir))@\(Int(spd))G\(Int(gust))"
        }
        return "\(Int(dir))@\(Int(spd))"
    }
}
