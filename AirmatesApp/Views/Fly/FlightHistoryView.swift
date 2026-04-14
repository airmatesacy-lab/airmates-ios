import SwiftUI

struct FlightHistoryView: View {
    @State private var flights: [Flight] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                LoadingView(message: "Loading flights...")
            } else if let error = errorMessage {
                ErrorView(message: error) { loadFlights() }
            } else if flights.isEmpty {
                EmptyStateView(icon: "airplane", title: "No Flights", message: "Your flight history will appear here.")
            } else {
                List(flights) { flight in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(flight.aircraft?.tailNumber ?? "Aircraft")
                                .font(.headline)
                            Text(String(flight.date.prefix(10)))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(String(format: "%.1f hrs", flight.hobbsTime))
                                .font(.subheadline.monospaced().bold())
                            HStack(spacing: 4) {
                                Text(flight.type ?? "")
                                    .font(.caption2)
                                if (flight.amount ?? 0) > 0 {
                                    Text(String(format: "$%.0f", flight.amount ?? 0))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Flight History")
        .task { await fetchFlights() }
    }

    private func loadFlights() { Task { await fetchFlights() } }

    private func fetchFlights() async {
        isLoading = flights.isEmpty
        do {
            flights = try await APIClient.shared.get("/api/flights")
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
