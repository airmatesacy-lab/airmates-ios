import SwiftUI

struct FlyView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = FlyViewModel()
    @State private var showCheckOut = false
    @State private var showCheckIn = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading {
                        LoadingView(message: "Loading flight status...")
                    } else if let checkout = viewModel.myActiveCheckout {
                        // Currently flying
                        ActiveFlightCard(checkout: checkout) {
                            showCheckIn = true
                        }
                    } else {
                        // Ready to fly
                        ReadyToFlyCard {
                            showCheckOut = true
                        }
                    }

                    // Other active checkouts
                    let otherCheckouts = viewModel.activeCheckouts.filter {
                        $0.isOut && $0.memberId != appState.currentUser?.id
                    }
                    if !otherCheckouts.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Currently Out")
                                .font(.headline)
                                .padding(.horizontal)
                            ForEach(otherCheckouts) { checkout in
                                OtherFlightRow(checkout: checkout)
                            }
                        }
                    }

                    // Recent flights
                    if !viewModel.recentFlights.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recent Flights")
                                .font(.headline)
                                .padding(.horizontal)
                            ForEach(viewModel.recentFlights.prefix(5)) { flight in
                                FlightRow(flight: flight)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Fly")
            .refreshable { await viewModel.loadAll(userId: appState.currentUser?.id) }
            .sheet(isPresented: $showCheckOut) {
                CheckOutSheet(aircraft: viewModel.aircraft, viewModel: viewModel) {
                    Task { await viewModel.loadAll(userId: appState.currentUser?.id) }
                }
                .environment(appState)
            }
            .sheet(isPresented: $showCheckIn) {
                if let checkout = viewModel.myActiveCheckout {
                    CheckInSheet(checkout: checkout, viewModel: viewModel) {
                        Task { await viewModel.loadAll(userId: appState.currentUser?.id) }
                    }
                    .environment(appState)
                }
            }
        }
        .task { await viewModel.loadAll(userId: appState.currentUser?.id) }
    }
}

struct ReadyToFlyCard: View {
    let onCheckOut: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 48))
                .foregroundColor(.brandBlue)
            Text("Ready to fly?")
                .font(.title2.bold())
            Button(action: onCheckOut) {
                Text("Check Out Aircraft")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brandBlue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 32)
    }
}

struct ActiveFlightCard: View {
    let checkout: Checkout
    let onCheckIn: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "airplane")
                .font(.system(size: 40))
                .foregroundColor(.brandBlue)

            Text("You're flying!")
                .font(.title2.bold())

            Text("\(checkout.aircraft?.tailNumber ?? "") \u{2022} \(checkout.aircraft?.type ?? "")")
                .font(.title3)

            // Booking type badge — pulled from the linked booking so the pilot
            // sees Solo/Dual/Maintenance at a glance without opening check-in.
            if let bookingType = checkout.booking?.type {
                Text(bookingType)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.bookingTypeBadgeColor(bookingType).opacity(0.12))
                    .foregroundColor(Color.bookingTypeBadgeColor(bookingType))
                    .cornerRadius(6)
            }

            Text(checkout.elapsedTimeFormatted)
                .font(.system(.largeTitle, design: .monospaced).bold())
                .foregroundColor(.brandBlue)

            HStack(spacing: 24) {
                VStack {
                    Text("\(checkout.meterType == "HOBBS" ? "Hobbs" : "Tach") Out")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", checkout.tachOut))
                        .font(.headline.monospaced())
                }
                if let dest = checkout.destination, !dest.isEmpty {
                    VStack {
                        Text("Destination")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(dest)
                            .font(.headline)
                    }
                }
            }

            Button(action: onCheckIn) {
                Text("Check In")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 24)
    }
}

struct OtherFlightRow: View {
    let checkout: Checkout

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(checkout.aircraft?.tailNumber ?? "Aircraft")
                    .font(.subheadline.bold())
                Text(checkout.member?.name ?? "Pilot")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(checkout.elapsedTimeFormatted)
                .font(.subheadline.monospaced())
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct FlightRow: View {
    let flight: Flight

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(flight.aircraft?.tailNumber ?? "Aircraft")
                    .font(.subheadline.bold())
                Text(flight.date.prefix(10))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(String(format: "%.1f hrs", flight.hobbsTime))
                    .font(.subheadline.monospaced())
                Text(flight.type ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}
