import SwiftUI

struct ScheduleView: View {
    @Environment(AppState.self) private var appState
    @State private var bookings: [Booking] = []
    @State private var selectedDate = Date()
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showBookingForm = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date picker
                DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding(.horizontal)
                    .tint(.brandBlue)

                Divider()

                // Bookings list
                if isLoading {
                    LoadingView(message: "Loading bookings...")
                } else if let errorMessage {
                    ErrorView(message: errorMessage) { loadBookings() }
                } else if bookings.isEmpty {
                    EmptyStateView(icon: "calendar.badge.plus", title: "No Bookings", message: "No bookings for this date. Tap + to book an aircraft.")
                } else {
                    List(bookings) { booking in
                        BookingRow(booking: booking)
                            .swipeActions(edge: .trailing) {
                                if booking.memberId == appState.currentUser?.id || appState.currentUser?.isAdmin == true {
                                    Button("Cancel", role: .destructive) {
                                        cancelBooking(booking)
                                    }
                                }
                            }
                    }
                    .listStyle(.plain)
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
            .onChange(of: selectedDate) { _, _ in loadBookings() }
            .sheet(isPresented: $showBookingForm) {
                BookingFormSheet(selectedDate: selectedDate) {
                    loadBookings()
                }
                .environment(appState)
            }
            .refreshable { await fetchBookings() }
        }
        .task { await fetchBookings() }
    }

    private func loadBookings() { Task { await fetchBookings() } }

    private func fetchBookings() async {
        isLoading = bookings.isEmpty
        errorMessage = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: selectedDate)

        do {
            bookings = try await APIClient.shared.get("/api/bookings", query: [
                URLQueryItem(name: "date", value: dateStr)
            ])
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func cancelBooking(_ booking: Booking) {
        Task {
            do {
                struct DeleteResponse: Decodable { var deleted: Bool }
                let _: DeleteResponse = try await APIClient.shared.delete("/api/bookings", query: [
                    URLQueryItem(name: "id", value: booking.id)
                ])
                loadBookings()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// BookingFormSheet has been moved to Views/Schedule/BookingFormSheet.swift
