import SwiftUI

struct WeatherCard: View {
    let weather: WeatherData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: weatherIcon)
                    .font(.title2)
                    .foregroundColor(categoryColor)
                Text(weather.icao ?? "----")
                    .font(.headline)
                if let category = weather.parsed?.flightCategory {
                    Text(category)
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(categoryColor.opacity(0.2))
                        .foregroundColor(categoryColor)
                        .cornerRadius(4)
                }
                Spacer()
                if let goNoGo = weather.goNoGo {
                    Label(goNoGo ? "GO" : "NO-GO", systemImage: goNoGo ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.caption.bold())
                        .foregroundColor(goNoGo ? .green : .red)
                }
            }

            if let parsed = weather.parsed {
                HStack(spacing: 16) {
                    Label(parsed.windDescription, systemImage: "wind")
                    if let vis = parsed.visibility {
                        Label("\(Int(vis))SM", systemImage: "eye")
                    }
                    if let temp = parsed.temp {
                        Label("\(Int(temp))\u{00B0}C", systemImage: "thermometer.medium")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)

                // Second row — ceiling, altimeter, dewpoint spread
                HStack(spacing: 16) {
                    if let ceiling = parsed.ceiling, ceiling < 99999 {
                        Label("\(Int(ceiling))ft", systemImage: "cloud.fill")
                    }
                    if let altimeter = parsed.altimeter {
                        Label(String(format: "%.2f\"", altimeter), systemImage: "gauge")
                    }
                    if let temp = parsed.temp, let dewp = parsed.dewp ?? parsed.dewpoint {
                        let spread = Int(temp - dewp)
                        Label("Spread \(spread)\u{00B0}", systemImage: "drop")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }

            if let issues = weather.issues, !issues.isEmpty {
                ForEach(issues, id: \.self) { issue in
                    Label(issue, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .padding(.horizontal)
    }

    var categoryColor: Color {
        switch weather.parsed?.flightCategory {
        case "VFR": return .green
        case "MVFR": return .blue
        case "IFR": return .red
        case "LIFR": return .purple
        default: return .gray
        }
    }

    var weatherIcon: String {
        switch weather.parsed?.flightCategory {
        case "VFR": return "sun.max.fill"
        case "MVFR": return "cloud.sun.fill"
        case "IFR": return "cloud.fill"
        case "LIFR": return "cloud.fog.fill"
        default: return "questionmark.circle"
        }
    }
}
