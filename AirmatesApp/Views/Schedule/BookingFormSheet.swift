import SwiftUI

struct BookingFormSheet: View {
    let initialDate: Date
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var aircraft: [Aircraft] = []
    @State private var instructors: [Instructor] = []
    @State private var members: [MemberSummary] = []
    @State private var selectedDate: Date
    @State private var selectedAircraftId = ""
    @State private var selectedInstructorId = ""
    @State private var selectedMemberId = "" // "Book For" — admin/instructor only
    @State private var startTime = "08:00"
    @State private var endTime = "10:00"
    @State private var bookingType = "SOLO"
    @State private var notes = ""
    @State private var isLoading = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showConflictAlert = false
    @State private var conflictMessage = ""

    init(selectedDate: Date, onComplete: @escaping () -> Void) {
        self.initialDate = selectedDate
        self.onComplete = onComplete
        _selectedDate = State(initialValue: selectedDate)
    }

    var isPrivileged: Bool {
        appState.currentUser?.isAdmin == true || appState.currentUser?.isInstructor == true
    }

    var body: some View {
        NavigationStack {
            Form {
                // Book For (admin/instructor only)
                if isPrivileged && !members.isEmpty {
                    Section("Book For") {
                        Picker("Member", selection: $selectedMemberId) {
                            Text("Myself").tag("")
                            ForEach(members) { member in
                                Text(member.name).tag(member.id)
                            }
                        }
                    }
                }

                Section("Aircraft") {
                    if aircraft.isEmpty && isLoading {
                        ProgressView()
                    } else {
                        Picker("Aircraft", selection: $selectedAircraftId) {
                            Text("Select...").tag("")
                            ForEach(aircraft) { ac in
                                HStack {
                                    Text("\(ac.tailNumber) — \(ac.type)")
                                    if !ac.isAvailable {
                                        Text(ac.isInFlight ? "(Out)" : ac.isInMaintenance ? "(Maint.)" : "")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .tag(ac.id)
                            }
                        }
                    }
                }

                Section("Date") {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                }

                Section("Time") {
                    Picker("Start", selection: $startTime) {
                        ForEach(AppConstants.timeSlots, id: \.self) { t in Text(t).tag(t) }
                    }
                    Picker("End", selection: $endTime) {
                        ForEach(AppConstants.timeSlots, id: \.self) { t in Text(t).tag(t) }
                    }
                }

                Section("Type") {
                    Picker("Flight Type", selection: $bookingType) {
                        Text("Solo").tag("SOLO")
                        Text("Dual (with instructor)").tag("DUAL")
                        if isPrivileged {
                            Text("Maintenance").tag("MAINTENANCE")
                        }
                    }

                    if bookingType == "DUAL" && !instructors.isEmpty {
                        Picker("Instructor", selection: $selectedInstructorId) {
                            Text("Select...").tag("")
                            ForEach(instructors.filter { $0.available == true }) { inst in
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
                    Button {
                        createBooking(asStandby: false)
                    } label: {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Book")
                        }
                    }
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

            // Only fetch members if admin/instructor (for "Book For" picker)
            if isPrivileged {
                members = try await APIClient.shared.get("/api/members")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Convert a local date string + time string to proper UTC ISO 8601.
    /// The web uses toEST() with Intl.DateTimeFormat to handle DST; the iOS
    /// equivalent is to let DateFormatter use TimeZone.current (the device's
    /// timezone, which should match the club's local time since the pilot is
    /// physically at the airport). This fixes the bug where the iOS app was
    /// appending "Z" (UTC) to local times, causing bookings to be offset by
    /// the timezone difference and breaking overlap/conflict detection.
    private func localToUTC(dateStr: String, timeStr: String) -> String {
        let local = DateFormatter()
        local.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        local.timeZone = TimeZone.current

        guard let date = local.date(from: "\(dateStr)T\(timeStr):00") else {
            // Fallback: return naive UTC (better than crashing)
            return "\(dateStr)T\(timeStr):00.000Z"
        }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return iso.string(from: date)
    }

    private func createBooking(asStandby: Bool) {
        isSubmitting = true
        errorMessage = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: selectedDate)

        // Convert local times to proper UTC
        let startDateISO = localToUTC(dateStr: dateStr, timeStr: startTime)
        let endDateISO = localToUTC(dateStr: dateStr, timeStr: endTime)

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
                    let memberId: String?
                    let notes: String?
                    let status: String?
                }

                let _: Booking = try await APIClient.shared.post("/api/bookings", body: BookingBody(
                    aircraftId: selectedAircraftId,
                    startDate: startDateISO,
                    endDate: endDateISO,
                    startTime: startTime,
                    endTime: endTime,
                    type: bookingType,
                    instructorId: bookingType == "DUAL" && !selectedInstructorId.isEmpty ? selectedInstructorId : nil,
                    memberId: !selectedMemberId.isEmpty ? selectedMemberId : nil,
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
