import SwiftUI

struct MyAccountView: View {
    @Environment(AppState.self) private var appState
    @State private var data: MyAccountData?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showCheckOut = false
    @State private var showCheckIn: Checkout?
    @State private var activeCheckouts: [Checkout] = []
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    LoadingView(message: "Loading account...")
                } else if let errorMessage {
                    ErrorView(message: errorMessage) { loadData() }
                } else if let data {
                    accountContent(data)
                }
            }
            .navigationTitle("My Account")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            showCheckOut = true
                        } label: {
                            Label("Check Out Aircraft", systemImage: "airplane.departure")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        appState.logout()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .sheet(isPresented: $showCheckOut) {
                CheckOutView { loadData() }
            }
            .sheet(item: $showCheckIn) { checkout in
                CheckInView(checkout: checkout) { loadData() }
            }
            .sheet(isPresented: $showEditProfile) {
                if let user = data?.user {
                    ProfileEditView(user: user) { loadData() }
                }
            }
            .refreshable { await fetchData() }
        }
        .task { await fetchData() }
    }

    @ViewBuilder
    private func accountContent(_ data: MyAccountData) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Balance card
                VStack(spacing: 8) {
                    Text("Account Balance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(data.balance.asCurrency)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(data.balance >= 0 ? .brandGreen : .brandRed)
                    Text(data.balance >= 0 ? "Credit" : "Amount Due")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

                // Profile summary
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Profile")
                            .font(.headline)
                        Spacer()
                        Button("Edit") { showEditProfile = true }
                            .font(.caption)
                    }

                    profileRow("Name", data.user.name)
                    profileRow("Email", data.user.email)
                    profileRow("Role", data.user.role.replacingOccurrences(of: "_", with: " "))
                    profileRow("Tier", data.user.membershipTier?.name ?? "None")
                    if let phone = data.user.phone {
                        profileRow("Phone", phone)
                    }
                    if let medical = data.user.medicalClass {
                        profileRow("Medical", "\(medical) — exp \(data.user.medicalExpiry?.toDisplayDate() ?? "N/A")")
                    }
                    if let hours = data.user.totalHours {
                        profileRow("Total Hours", hours.asHours)
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

                // Active checkouts (if any)
                if !activeCheckouts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Checkouts")
                            .font(.headline)
                        ForEach(activeCheckouts) { checkout in
                            Button {
                                showCheckIn = checkout
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(checkout.aircraft?.tailNumber ?? "Unknown")
                                            .font(.subheadline.bold())
                                        Text("Tach: \(String(format: "%.1f", checkout.tachOut))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("Check In")
                                        .font(.caption.bold())
                                        .foregroundColor(.brandBlue)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                }

                // Recent transactions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Transactions")
                        .font(.headline)
                    if data.transactions.isEmpty {
                        Text("No transactions yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(data.transactions.prefix(20)) { txn in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(txn.description)
                                        .font(.caption)
                                        .lineLimit(1)
                                    Text(txn.createdAt?.toShortDate() ?? "")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(txn.amount.asCurrency)
                                    .font(.subheadline.bold())
                                    .foregroundColor(txn.amount < 0 ? .brandGreen : .brandRed)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

                // Recent flights
                if !data.flights.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Flights")
                            .font(.headline)
                        ForEach(data.flights.prefix(10)) { flight in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(flight.aircraft?.tailNumber ?? "")
                                        .font(.subheadline.bold())
                                    Text(flight.date.toShortDate())
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(flight.hobbsTime.asHours)
                                        .font(.subheadline)
                                    Text(flight.amount.asCurrency)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
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

    private func profileRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.subheadline)
        }
    }

    private func loadData() { Task { await fetchData() } }

    private func fetchData() async {
        isLoading = data == nil
        errorMessage = nil
        do {
            async let accountReq: MyAccountData = APIClient.shared.get("/api/my-account")
            async let checkoutsReq: [Checkout] = APIClient.shared.get("/api/checkouts")

            let (account, checkouts) = try await (accountReq, checkoutsReq)
            data = account
            activeCheckouts = checkouts.filter { $0.isOut && $0.memberId == appState.currentUser?.id }
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

extension Checkout: Identifiable {}
