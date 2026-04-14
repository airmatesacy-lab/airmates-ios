import SwiftUI

enum ScheduleViewMode: String, CaseIterable {
    case month = "Month"
    case list = "List"
}

struct ScheduleViewV2: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = ScheduleViewModel()
    @State private var showBookingForm = false
    @State private var selectedBooking: Booking?
    @State private var viewMode: ScheduleViewMode = .month

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // View mode toggle
                Picker("View", selection: $viewMode) {
                    ForEach(ScheduleViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                switch viewMode {
                case .month:
                    monthView
                case .list:
                    listView
                }
            }
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showBookingForm = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onChange(of: viewModel.selectedDate) { _, _ in
                Task {
                    await viewModel.fetchBookings()
                    await viewModel.fetchMonthBookings()
                }
            }
            .sheet(isPresented: $showBookingForm) {
                BookingFormSheet(selectedDate: viewModel.selectedDate) {
                    Task {
                        await viewModel.fetchBookings()
                        await viewModel.fetchMonthBookings()
                    }
                }
                .environment(appState)
            }
            .sheet(item: $selectedBooking) { booking in
                BookingDetailSheet(booking: booking, onUpdate: {
                    Task {
                        await viewModel.fetchBookings()
                        await viewModel.fetchMonthBookings()
                    }
                })
                .environment(appState)
            }
            .refreshable {
                await viewModel.fetchBookings()
                await viewModel.fetchMonthBookings()
            }
        }
        .task {
            await viewModel.fetchBookings()
            await viewModel.fetchMonthBookings()
        }
    }

    // MARK: - Month View

    @ViewBuilder
    var monthView: some View {
        // Calendar
        DatePicker("Date", selection: $viewModel.selectedDate, displayedComponents: .date)
            .datePickerStyle(.graphical)
            .padding(.horizontal)
            .tint(.brandBlue)

        // Date chips — show dates that have bookings
        if !viewModel.bookedDates.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.sortedBookedDates, id: \.self) { dateStr in
                        DateChip(
                            dateString: dateStr,
                            isSelected: isSelectedDate(dateStr),
                            bookingCount: viewModel.bookingCount(for: dateStr)
                        ) {
                            selectDate(dateStr)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
        }

        Divider()

        // Day's bookings
        if viewModel.isLoading {
            LoadingView(message: "Loading bookings...")
        } else if viewModel.selectedDayBookings.isEmpty {
            EmptyStateView(
                icon: "calendar.badge.plus",
                title: "No Bookings",
                message: "No bookings for this date."
            )
        } else {
            bookingsList(viewModel.selectedDayBookings)
        }
    }

    // MARK: - List View

    @ViewBuilder
    var listView: some View {
        if viewModel.monthBookings.isEmpty {
            EmptyStateView(
                icon: "calendar",
                title: "No Upcoming Bookings",
                message: "No bookings this month."
            )
        } else {
            List {
                ForEach(groupedBookings.keys.sorted(), id: \.self) { dateKey in
                    Section(dateKey) {
                        ForEach(groupedBookings[dateKey] ?? []) { booking in
                            BookingRowV2(booking: booking, currentUserId: appState.currentUser?.id)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedBooking = booking }
                                .swipeActions(edge: .trailing) {
                                    if booking.memberId == appState.currentUser?.id || appState.currentUser?.isAdmin == true {
                                        Button("Cancel", role: .destructive) {
                                            Task { await viewModel.cancelBooking(booking) }
                                        }
                                    }
                                }
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Shared

    @ViewBuilder
    func bookingsList(_ bookings: [Booking]) -> some View {
        List(bookings) { booking in
            BookingRowV2(booking: booking, currentUserId: appState.currentUser?.id)
                .contentShape(Rectangle())
                .onTapGesture { selectedBooking = booking }
                .swipeActions(edge: .trailing) {
                    if booking.memberId == appState.currentUser?.id || appState.currentUser?.isAdmin == true {
                        Button("Cancel", role: .destructive) {
                            Task { await viewModel.cancelBooking(booking) }
                        }
                    }
                }
        }
        .listStyle(.plain)
    }

    var groupedBookings: [String: [Booking]] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let display = DateFormatter()
        display.dateFormat = "EEEE, MMM d"

        var groups: [String: [Booking]] = [:]
        for booking in viewModel.monthBookings.sorted(by: { $0.startDate < $1.startDate }) {
            if let date = DateFormatter.apiDate.date(from: booking.startDate) {
                let key = display.string(from: date)
                groups[key, default: []].append(booking)
            }
        }
        return groups
    }

    func isSelectedDate(_ dateStr: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return dateStr == formatter.string(from: viewModel.selectedDate)
    }

    func selectDate(_ dateStr: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateStr) {
            viewModel.selectedDate = date
        }
    }
}

// MARK: - Date Chip

struct DateChip: View {
    let dateString: String
    let isSelected: Bool
    let bookingCount: Int
    let onTap: () -> Void

    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let display = DateFormatter()
        display.dateFormat = "MMM d"
        if let date = formatter.date(from: dateString) {
            return display.string(from: date)
        }
        return dateString
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(displayDate)
                    .font(.caption.bold())
                if bookingCount > 0 {
                    Text("\(bookingCount)")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                        .background(Color.brandBlue)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.brandBlue.opacity(0.15) : Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.brandBlue : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Booking Row

struct BookingRowV2: View {
    let booking: Booking
    var currentUserId: String?

    private var isMine: Bool {
        if let uid = currentUserId { return booking.memberId == uid }
        return false
    }

    /// Matches web bColor() exactly — status > maintenance > mine > aircraft color > aircraft type > blue
    private var barColor: Color {
        Color.bookingColor(
            type: booking.type,
            status: booking.status,
            aircraftType: booking.aircraft?.type,
            bookingColor: booking.aircraft?.bookingColor,
            isMine: isMine
        )
    }

    /// Badge color for the type label (SOLO=green, DUAL=blue, MAINTENANCE=slate)
    private var typeBadgeColor: Color {
        Color.bookingTypeBadgeColor(booking.type)
    }

    var body: some View {
        HStack {
            // Color bar — matches web calendar chip colors
            RoundedRectangle(cornerRadius: 2)
                .fill(barColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(booking.aircraft?.tailNumber ?? "Aircraft")
                        .font(.headline)
                    Text(booking.aircraft?.type ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if isMine {
                        Text("YOU")
                            .font(.caption2.bold())
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.bookingAmber.opacity(0.15))
                            .foregroundColor(Color(red: 146/255, green: 64/255, blue: 14/255)) // #92400e
                            .cornerRadius(3)
                    }
                }
                HStack {
                    Text("\(booking.startTime) \u{2013} \(booking.endTime)")
                        .font(.subheadline)
                    Text(booking.type)
                        .font(.caption.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(typeBadgeColor.opacity(0.1))
                        .foregroundColor(typeBadgeColor)
                        .cornerRadius(4)
                    if booking.isStandby {
                        Text("STANDBY")
                            .font(.caption2.bold())
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.bookingYellow.opacity(0.15))
                            .foregroundColor(Color(red: 161/255, green: 98/255, blue: 7/255)) // #a16207
                            .cornerRadius(3)
                    }
                }
                if let member = booking.member {
                    Text(member.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
