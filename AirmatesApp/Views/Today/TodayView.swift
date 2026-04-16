import SwiftUI

struct TodayView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = TodayViewModel()
    @State private var selectedBooking: Booking?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Greeting
                    if let name = appState.currentUser?.name.components(separatedBy: " ").first {
                        HStack {
                            Text("Good \(greeting), \(name)")
                                .font(.title2.bold())
                            Spacer()
                        }
                        .padding(.horizontal)
                    }

                    // Active checkout banner
                    if let checkout = viewModel.activeCheckout {
                        ActiveFlightBanner(checkout: checkout)
                    }

                    // Weather
                    if let weather = viewModel.weather {
                        WeatherCard(weather: weather)
                    }

                    // Next flight — tap to manage (edit, cancel)
                    if let booking = viewModel.nextBooking {
                        NextFlightCard(booking: booking)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedBooking = booking }
                    }

                    // Balance — tap to go to account/payment
                    NavigationLink(destination: MyAccountView().environment(appState)) {
                        BalanceCard(
                            balance: viewModel.personalBalance,
                            tier: appState.currentUser?.membershipTier
                        )
                    }
                    .buttonStyle(.plain)

                    // Fleet status
                    if let fleet = viewModel.fleetSummary {
                        FleetStatusCard(summary: fleet)
                    }

                    // Error banner
                    if let error = viewModel.errorMessage {
                        HStack {
                            Image(systemName: "wifi.slash")
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }

                    // Announcements
                    ForEach(viewModel.announcements) { announcement in
                        AnnouncementCard(announcement: announcement) {
                            Task { await viewModel.dismissAnnouncement(announcement) }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Today")
            .refreshable {
                viewModel.userId = appState.currentUser?.id
                await viewModel.loadAll()
            }
            .sheet(item: $selectedBooking) { booking in
                BookingDetailSheet(booking: booking) {
                    Task {
                        viewModel.userId = appState.currentUser?.id
                        await viewModel.loadAll()
                    }
                }
                .environment(appState)
            }
        }
        .task {
            viewModel.userId = appState.currentUser?.id
            await viewModel.loadAll()
        }
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "morning" }
        if hour < 17 { return "afternoon" }
        return "evening"
    }
}

struct ActiveFlightBanner: View {
    let checkout: Checkout

    var body: some View {
        HStack {
            Image(systemName: "airplane")
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("You're flying!")
                    .font(.headline)
                Text("\(checkout.aircraft?.tailNumber ?? "Aircraft") \u{2022} \(checkout.elapsedTimeFormatted)")
                    .font(.subheadline)
            }
            Spacer()
            Image(systemName: "chevron.right")
        }
        .padding()
        .background(Color.brandBlue.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
