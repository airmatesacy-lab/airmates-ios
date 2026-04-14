import SwiftUI

struct BookingDetailSheet: View {
    let booking: Booking
    let onUpdate: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var showCancelConfirm = false
    @State private var isDeleting = false
    @State private var isEditing = false
    @State private var errorMessage: String?

    // Edit state
    @State private var editStartTime: String
    @State private var editEndTime: String
    @State private var editType: String
    @State private var editNotes: String
    @State private var isSaving = false

    init(booking: Booking, onUpdate: @escaping () -> Void) {
        self.booking = booking
        self.onUpdate = onUpdate
        _editStartTime = State(initialValue: booking.startTime)
        _editEndTime = State(initialValue: booking.endTime)
        _editType = State(initialValue: booking.type)
        _editNotes = State(initialValue: booking.notes ?? "")
    }

    var canCancel: Bool {
        booking.isPending || booking.isStandby
    }

    var canEdit: Bool {
        (booking.memberId == appState.currentUser?.id || appState.currentUser?.isAdmin == true)
        && (booking.isPending || booking.isStandby)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Flight Details") {
                    LabeledContent("Aircraft", value: "\(booking.aircraft?.tailNumber ?? "") \(booking.aircraft?.type ?? "")")
                    LabeledContent("Date", value: booking.formattedDateRange)

                    if isEditing {
                        Picker("Start", selection: $editStartTime) {
                            ForEach(AppConstants.timeSlots, id: \.self) { t in Text(t).tag(t) }
                        }
                        Picker("End", selection: $editEndTime) {
                            ForEach(AppConstants.timeSlots, id: \.self) { t in Text(t).tag(t) }
                        }
                        Picker("Type", selection: $editType) {
                            Text("Solo").tag("SOLO")
                            Text("Dual").tag("DUAL")
                            Text("Maintenance").tag("MAINTENANCE")
                        }
                    } else {
                        LabeledContent("Time", value: "\(booking.startTime) \u{2013} \(booking.endTime)")
                        LabeledContent("Type", value: booking.type)
                    }
                    LabeledContent("Status", value: booking.status)
                }

                if let member = booking.member {
                    Section("Pilot") {
                        LabeledContent("Name", value: member.name)
                        if let email = member.email {
                            LabeledContent("Email", value: email)
                        }
                    }
                }

                if let instructor = booking.instructor {
                    Section("Instructor") {
                        LabeledContent("Name", value: instructor.user?.name ?? "Unknown")
                    }
                }

                if isEditing {
                    Section("Notes") {
                        TextField("Notes...", text: $editNotes, axis: .vertical)
                            .lineLimit(2...4)
                    }
                } else if let notes = booking.notes, !notes.isEmpty {
                    Section("Notes") {
                        Text(notes)
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error).foregroundColor(.red)
                    }
                }

                if canEdit && !isEditing {
                    Section {
                        Button("Cancel Booking", role: .destructive) {
                            showCancelConfirm = true
                        }
                        .disabled(isDeleting)
                    }
                }
            }
            .navigationTitle("Booking Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditing ? "Cancel" : "Done") {
                        if isEditing {
                            isEditing = false
                        } else {
                            dismiss()
                        }
                    }
                }
                if canEdit {
                    ToolbarItem(placement: .confirmationAction) {
                        if isEditing {
                            Button {
                                saveChanges()
                            } label: {
                                if isSaving { ProgressView() } else { Text("Save") }
                            }
                            .disabled(isSaving)
                        } else {
                            Button("Edit") { isEditing = true }
                        }
                    }
                }
            }
            .alert("Cancel Booking?", isPresented: $showCancelConfirm) {
                Button("Cancel Booking", role: .destructive) { cancelBooking() }
                Button("Keep", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
            }
        }
    }

    func saveChanges() {
        isSaving = true
        errorMessage = nil
        Task {
            struct UpdateBody: Encodable {
                let id: String
                let startTime: String
                let endTime: String
                let type: String
                let notes: String?
            }
            do {
                let _: Booking = try await APIClient.shared.patch("/api/bookings", body: UpdateBody(
                    id: booking.id,
                    startTime: editStartTime,
                    endTime: editEndTime,
                    type: editType,
                    notes: editNotes.isEmpty ? nil : editNotes
                ))
                isEditing = false
                onUpdate()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }

    func cancelBooking() {
        isDeleting = true
        Task {
            struct DeleteResponse: Decodable { var deleted: Bool }
            do {
                let _: DeleteResponse = try await APIClient.shared.delete("/api/bookings", query: [
                    URLQueryItem(name: "id", value: booking.id),
                ])
                onUpdate()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isDeleting = false
        }
    }
}
