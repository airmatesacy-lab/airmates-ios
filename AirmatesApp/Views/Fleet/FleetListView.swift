import SwiftUI

struct FleetListView: View {
    @State private var aircraft: [Aircraft] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    LoadingView(message: "Loading fleet...")
                } else if let errorMessage {
                    ErrorView(message: errorMessage) { loadData() }
                } else if aircraft.isEmpty {
                    EmptyStateView(icon: "airplane", title: "No Aircraft", message: "No aircraft have been added yet.")
                } else {
                    List(aircraft) { ac in
                        NavigationLink(value: ac) {
                            AircraftRow(aircraft: ac)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Fleet")
            .navigationDestination(for: Aircraft.self) { ac in
                AircraftDetailView(aircraft: ac)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { loadData() } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .refreshable { await fetchData() }
        }
        .task { await fetchData() }
    }

    private func loadData() { Task { await fetchData() } }

    private func fetchData() async {
        isLoading = aircraft.isEmpty
        errorMessage = nil
        do {
            aircraft = try await APIClient.shared.get("/api/aircraft")
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

struct AircraftRow: View {
    let aircraft: Aircraft

    var body: some View {
        HStack(spacing: 12) {
            // Aircraft icon with status color
            ZStack {
                Circle()
                    .fill(Color.statusColor(aircraft.status).opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "airplane")
                    .font(.title3)
                    .foregroundColor(Color.statusColor(aircraft.status))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(aircraft.tailNumber)
                    .font(.headline)
                Text(aircraft.type)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack(spacing: 8) {
                    Text("Tach: \(String(format: "%.1f", aircraft.tachCurrent))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(aircraft.hourlyRate.asCurrency + "/hr")
                        .font(.caption)
                        .foregroundColor(.brandBlue)
                }
            }

            Spacer()

            StatusBadge(status: aircraft.status)
        }
        .padding(.vertical, 4)
    }
}
