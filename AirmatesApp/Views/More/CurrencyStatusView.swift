import SwiftUI

struct CurrencyStatusView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        List {
            if let user = appState.currentUser {
                Section("Flight Currency") {
                    CurrencyRow(
                        title: "Passenger (Day)",
                        subtitle: "3 takeoffs/landings in 90 days",
                        lastDate: user.lastPassengerFlight,
                        daysValid: 90
                    )
                    CurrencyRow(
                        title: "Night",
                        subtitle: "3 night takeoffs/full-stop landings in 90 days",
                        lastDate: user.lastNightFlight,
                        daysValid: 90
                    )
                    CurrencyRow(
                        title: "Instrument",
                        subtitle: "6 approaches + holding in 6 months",
                        lastDate: user.lastIFRActivity,
                        daysValid: 180
                    )
                }

                Section("Medical Certificate") {
                    if let medClass = user.medicalClass {
                        LabeledContent("Class", value: medClass)
                    }
                    if let expiry = user.medicalExpiry {
                        CurrencyDateRow(title: "Expires", dateString: expiry)
                    } else {
                        Text("No medical on file")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Flight Review") {
                    if let expiry = user.flightReviewExpiry {
                        CurrencyDateRow(title: "Expires", dateString: expiry)
                    } else {
                        Text("No flight review on file")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Currency Status")
    }
}

struct CurrencyRow: View {
    let title: String
    let subtitle: String
    let lastDate: String?
    let daysValid: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(statusText)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(0.15))
                    .foregroundColor(statusColor)
                    .clipShape(Capsule())
            }
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
            if let date = lastDate {
                Text("Last: \(String(date.prefix(10)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    var isCurrent: Bool {
        guard let date = lastDate,
              let parsed = DateFormatter.apiDate.date(from: date),
              let expiry = Calendar.current.date(byAdding: .day, value: daysValid, to: parsed)
        else { return false }
        return expiry > Date()
    }

    var statusText: String { isCurrent ? "Current" : lastDate != nil ? "Expired" : "Unknown" }
    var statusColor: Color { isCurrent ? .green : .red }
}

struct CurrencyDateRow: View {
    let title: String
    let dateString: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            let dateStr = String(dateString.prefix(10))
            Text(dateStr)
                .foregroundColor(isExpired ? .red : .primary)
            if isExpired {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }
        }
    }

    var isExpired: Bool {
        guard let date = DateFormatter.apiDate.date(from: dateString) else { return false }
        return date < Date()
    }
}
