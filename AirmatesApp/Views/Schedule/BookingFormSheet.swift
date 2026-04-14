import SwiftUI

struct BookingFormSheet: View {
    let selectedDate: Date
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var aircraft: [Aircraft] = []
    @State private var instructors: [Instructor] = []
    @State private var members: [MemberSummary] = []
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
                            ForEach(aircraft.filter { $0.isAvailable }) { ac in
                                Text("\(ac.tailNumber) — \(ac.type)").tag(ac.id)
                            }
                        }
                    }
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
                    let memberId: String?
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
