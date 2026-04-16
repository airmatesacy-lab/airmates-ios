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
    @State private var sharedWith: [String] = [] // member IDs for split flights
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

    /// Members available to add as shared flight participants
    /// (excludes self and anyone already selected)
    var availableMembers: [MemberSummary] {
        let selfId = appState.currentUser?.id ?? ""
        return members.filter { m in
            m.id != selfId &&
            !sharedWith.contains(m.id) &&
            (m.active ?? true)
        }
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

                // Split Flight With — only for SOLO flights (matches web behavior)
                if bookingType == "SOLO" && !members.isEmpty {
                    Section {
                        // Selected pilots (blue chips with remove)
                        if !sharedWith.isEmpty {
                            FlowLayout(spacing: 6) {
                                ForEach(sharedWith, id: \.self) { memberId in
                                    if let member = members.first(where: { $0.id == memberId }) {
                                        HStack(spacing: 4) {
                                            Text(member.name)
                                                .font(.caption.bold())
                                            Button {
                                                sharedWith.removeAll { $0 == memberId }
                                            } label: {
                                                Image(systemName: "xmark")
                                                    .font(.caption2.bold())
                                            }
                                            .buttonStyle(.plain)
                                            .foregroundColor(.red)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.brandBlue.opacity(0.1))
                                        .foregroundColor(.brandBlue)
                                        .cornerRadius(6)
                                    }
                                }
                            }
                        }

                        // Add pilot picker
                        if !availableMembers.isEmpty {
                            Picker("Add a pilot...", selection: Binding(
                                get: { "" },
                                set: { newId in
                                    if !newId.isEmpty {
                                        sharedWith.append(newId)
                                    }
                                }
                            )) {
                                Text("Add a pilot...").tag("")
                                ForEach(availableMembers) { member in
                                    Text(member.name).tag(member.id)
                                }
                            }
                        }

                        if !sharedWith.isEmpty {
                            Text("Flight time and cost will be split equally among \(sharedWith.count + 1) pilots. Each invited pilot will receive an email to confirm or decline.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text("Split Flight With")
                    } footer: {
                        if sharedWith.isEmpty {
                            Text("Optional — select members to split flight time and cost equally")
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
            // Always fetch members — needed for "Split Flight With" picker
            // (not just admin/instructor "Book For" picker)
            async let membersReq: [MemberSummary] = APIClient.shared.get("/api/members")

            aircraft = try await aircraftReq
            instructors = try await instructorsReq
            members = try await membersReq
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Convert a local date string + time string to proper UTC ISO 8601.
    private func localToUTC(dateStr: String, timeStr: String) -> String {
        let local = DateFormatter()
        local.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        local.timeZone = TimeZone.current

        guard let date = local.date(from: "\(dateStr)T\(timeStr):00") else {
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
                    let sharedWith: [String]?
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
                    status: asStandby ? "STANDBY" : nil,
                    sharedWith: sharedWith.isEmpty ? nil : sharedWith
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

// MARK: - Flow Layout (wrapping horizontal chips)

/// Simple wrapping layout for selected-pilot chips.
/// Falls back to VStack on older iOS.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, containerWidth: proposal.width ?? .infinity).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = layout(sizes: sizes, containerWidth: bounds.width).offsets
        for (i, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + offsets[i].x, y: bounds.minY + offsets[i].y), proposal: .unspecified)
        }
    }

    private func layout(sizes: [CGSize], containerWidth: CGFloat) -> (offsets: [CGPoint], size: CGSize) {
        var offsets: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for size in sizes {
            if x + size.width > containerWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            offsets.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxWidth = max(maxWidth, x)
        }

        return (offsets, CGSize(width: maxWidth, height: y + rowHeight))
    }
}
