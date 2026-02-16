import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var data: DashboardData?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    LoadingView(message: "Loading dashboard...")
                } else if let errorMessage {
                    ErrorView(message: errorMessage) { loadData() }
                } else if let data {
                    dashboardContent(data)
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        loadData()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .refreshable { await fetchData() }
        }
        .task { await fetchData() }
    }

    @ViewBuilder
    private func dashboardContent(_ data: DashboardData) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(title: "Aircraft", value: "\(data.aircraftCount)", icon: "airplane", color: .brandBlue)
                    StatCard(title: "Currently Out", value: "\(data.activeCheckouts)", icon: "paperplane.fill", color: data.activeCheckouts > 0 ? .brandOrange : .brandGreen)
                    StatCard(title: "Members", value: "\(data.memberCount)", icon: "person.3", color: .brandBlue)
                    StatCard(title: "Instructors", value: "\(data.instructorCount)", icon: "graduationcap", color: .purple)
                }

                // My upcoming bookings
                if !data.myUpcomingBookings.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("My Upcoming Bookings")
                            .font(.headline)
                        ForEach(data.myUpcomingBookings) { booking in
                            BookingRow(booking: booking)
                        }
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                }

                // Today's bookings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Flights")
                        .font(.headline)
                    if data.todayBookings.isEmpty {
                        Text("No flights scheduled today")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(data.todayBookings) { booking in
                            BookingRow(booking: booking)
                        }
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

                // Active checkouts
                if !data.recentCheckouts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Aircraft Currently Out")
                            .font(.headline)
                        ForEach(data.recentCheckouts) { checkout in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(checkout.aircraft?.tailNumber ?? "Unknown")
                                        .font(.subheadline.bold())
                                    Text(checkout.member?.name ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if let dest = checkout.destination {
                                    Text(dest)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                StatusBadge(status: "OUT")
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                }
            }
            .padding()
        }
        .background(Color.subtleBackground)
    }

    private func loadData() {
        Task { await fetchData() }
    }

    private func fetchData() async {
        isLoading = data == nil
        errorMessage = nil
        do {
            data = try await APIClient.shared.get("/api/dashboard")
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

struct BookingRow: View {
    let booking: Booking

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(booking.aircraft?.tailNumber ?? "")
                        .font(.subheadline.bold())
                    if let type = booking.aircraft?.type {
                        Text(type)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                HStack(spacing: 4) {
                    Text(booking.startDate.toShortDate())
                        .font(.caption)
                    Text("\(booking.startTime)–\(booking.endTime)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let name = booking.member?.name {
                    Text(name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            StatusBadge(status: booking.status)
        }
        .padding(.vertical, 4)
    }
}
