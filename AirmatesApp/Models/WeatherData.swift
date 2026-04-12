import Foundation

struct WeatherData: Codable {
    var icao: String?
    var metar: String?
    var parsed: ParsedMetar?
    var goNoGo: Bool?
    var issues: [String]?
    var hasMinimums: Bool?
}

struct ParsedMetar: Codable {
    var ceiling: Int?
    var visibility: Double?
    var windSpeed: Int?
    var windDirection: Int?
    var gustSpeed: Int?
    var temperature: Int?
    var dewpoint: Int?
    var altimeter: Double?
    var flightCategory: String? // VFR, MVFR, IFR, LIFR

    var flightCategoryColor: String {
        switch flightCategory {
        case "VFR": return "green"
        case "MVFR": return "blue"
        case "IFR": return "red"
        case "LIFR": return "purple"
        default: return "gray"
        }
    }

    var windDescription: String {
        guard let dir = windDirection, let spd = windSpeed else { return "Calm" }
        if let gust = gustSpeed {
            return "\(dir)@\(spd)G\(gust)"
        }
        return "\(dir)@\(spd)"
    }
}
