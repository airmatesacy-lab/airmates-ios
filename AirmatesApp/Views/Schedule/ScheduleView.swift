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

struct BookingFormSheet: View {
    let selectedDate: Date
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var aircraft: [Aircraft] = []
    @State private var instructors: [Instructor] = []
    @State private var selectedAircraftId = ""
    @State private var selectedInstructorId = ""
    @State private var startTime = "08:00"
    @State private var endTime = "10:00"
    @State private var bookingType = "SOLO"
    @State private var notes = ""
    @State private var isLoading = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showConflictAlert = false
    @State private var conflictMessage = ""

    let times = stride(from: 6, through: 20, by: 1).flatMap { hour in
        ["00", "30"].map { min in String(format: "%02d:%@", hour, min) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Aircraft") {
                    if aircraft.isEmpty {
                        ProgressView()
                    } else {
                        Picker("Aircraft", selection: $selectedAircraftId) {
                            Text("Select...").tag("")
                            ForEach(aircraft.filter { $0.isAvailable }) { ac in
                                Text("\(ac.tailNumber) — \(ac.type)").tag(ac.id)
                            }
                        }
                    }
                }

                Section("Time") {
                    Picker("Start", selection: $startTime) {
                        ForEach(times, id: \.self) { t in Text(t).tag(t) }
                    }
                    Picker("End", selection: $endTime) {
                        ForEach(times, id: \.self) { t in Text(t).tag(t) }
                    }
                }

                Section("Type") {
                    Picker("Flight Type", selection: $bookingType) {
                        Text("Solo").tag("SOLO")
                        Text("Dual (with instructor)").tag("DUAL")
                    }

                    if bookingType == "DUAL" && !instructors.isEmpty {
                        Picker("Instructor", selection: $selectedInstructorId) {
                            Text("Select...").tag("")
                            ForEach(instructors.filter { $0.available }) { inst in
                                Text(inst.user?.name ?? "Unknown").tag(inst.id)
                            }
                        }
                    }
                }

                Section("Notes") {
                    TextField("Optional notes...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Booking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Book") { createBooking(asStandby: false) }
                        .disabled(selectedAircraftId.isEmpty || isSubmitting)
                }
            }
            .alert("Time Conflict", isPresented: $showConflictAlert) {
                Button("Book as Standby") { createBooking(asStandby: true) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(conflictMessage + "\n\nWould you like to create a standby booking instead?")
            }
        }
        .task { await loadFormData() }
    }

    private func loadFormData() async {
        isLoading = true
        do {
            async let aircraftReq: [Aircraft] = APIClient.shared.get("/api/aircraft")
            async let instructorsReq: [Instructor] = APIClient.shared.get("/api/instructors")
            aircraft = try await aircraftReq
            instructors = try await instructorsReq
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func createBooking(asStandby: Bool) {
        isSubmitting = true
        errorMessage = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: selectedDate)

        Task {
            do {
                struct BookingBody: Encodable {
                    let aircraftId: String
                    let startDate: String
                    let endDate: String
                    let startTime: String
                    let endTime: String
                    let type: String
                    let instructorId: String?
                    let notes: String?
                    let status: String?
                }

                let _: Booking = try await APIClient.shared.post("/api/bookings", body: BookingBody(
                    aircraftId: selectedAircraftId,
                    startDate: "\(dateStr)T\(startTime):00.000Z",
                    endDate: "\(dateStr)T\(endTime):00.000Z",
                    startTime: startTime,
                    endTime: endTime,
                    type: bookingType,
                    instructorId: bookingType == "DUAL" && !selectedInstructorId.isEmpty ? selectedInstructorId : nil,
                    notes: notes.isEmpty ? nil : notes,
                    status: asStandby ? "STANDBY" : nil
                ))
                onComplete()
                dismiss()
            } catch let err as APIError {
                if case .conflict(let msg, _) = err {
                    conflictMessage = msg
                    showConflictAlert = true
                } else {
                    errorMessage = err.errorDescription
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}
