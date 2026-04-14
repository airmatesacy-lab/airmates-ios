import SwiftUI

struct CheckOutSheet: View {
    let aircraft: [Aircraft]
    let viewModel: FlyViewModel
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var selectedAircraftId = ""
    @State private var tachOut = ""
    @State private var destination = ""
    @State private var selectedMemberId = "" // "Check out for" — admin/instructor only
    @State private var members: [MemberSummary] = []
    @State private var isSubmitting = false
    @State private var showNoticeSheet = false

    var isPrivileged: Bool {
        appState.currentUser?.isAdmin == true || appState.currentUser?.isInstructor == true
    }

    var selectedAircraft: Aircraft? {
        aircraft.first { $0.id == selectedAircraftId }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Aircraft picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Aircraft")
                            .font(.headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(aircraft.filter { $0.isAvailable }) { ac in
                                    AircraftPickerCard(
                                        aircraft: ac,
                                        isSelected: ac.id == selectedAircraftId
                                    ) {
                                        selectedAircraftId = ac.id
                                        tachOut = String(format: "%.1f", ac.tachCurrent ?? 0)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Check out for (admin/instructor only)
                    if isPrivileged && !members.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Checking out for")
                                .font(.headline)
                            Picker("Member", selection: $selectedMemberId) {
                                Text("Myself").tag("")
                                ForEach(members) { member in
                                    Text(member.name).tag(member.id)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        .padding(.horizontal)
                    }

                    if !selectedAircraftId.isEmpty {
                        // Tach entry
                        TachPadView(
                            value: $tachOut,
                            label: "\(meterLabel) Out",
                            prefilledValue: selectedAircraft?.tachCurrent
                        )
                        .padding(.horizontal)

                        // Destination
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Destination (optional)")
                                .font(.headline)
                            TextField("Local, KPHL, etc.", text: $destination)
                                .textFieldStyle(.roundedBorder)
                        }
                        .padding(.horizontal)

                        // Error
                        if let error = viewModel.checkoutError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }

                        // Check out button
                        Button {
                            checkOut()
                        } label: {
                            HStack {
                                if isSubmitting {
                                    ProgressView().tint(.white)
                                }
                                Text("Check Out")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canCheckOut ? Color.brandBlue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!canCheckOut || isSubmitting)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Check Out")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                if isPrivileged {
                    do {
                        members = try await APIClient.shared.get("/api/members")
                    } catch {}
                }
            }
            .sheet(isPresented: $showNoticeSheet) {
                NoticeAckSheet(
                    notices: viewModel.unackedNotices,
                    viewModel: viewModel,
                    onAllAcknowledged: { performCheckOut() }
                )
            }
        }
    }

    var meterLabel: String {
        selectedAircraft?.meterType == "HOBBS" ? "Hobbs" : "Tach"
    }

    var canCheckOut: Bool {
        !selectedAircraftId.isEmpty && !tachOut.isEmpty && Double(tachOut) != nil
    }

    func checkOut() {
        isSubmitting = true
        Task {
            // First check for unacknowledged notices
            await viewModel.fetchNotices(for: selectedAircraftId)
            if !viewModel.unackedNotices.isEmpty {
                isSubmitting = false
                showNoticeSheet = true
                return
            }
            performCheckOut()
        }
    }

    func performCheckOut() {
        Task {
            let success = await viewModel.checkOut(
                aircraftId: selectedAircraftId,
                tachOut: tachOut,
                destination: destination.isEmpty ? nil : destination,
                forMemberId: selectedMemberId.isEmpty ? nil : selectedMemberId,
                currentUserId: appState.currentUser?.id
            )
            isSubmitting = false
            if success {
                onComplete()
                dismiss()
            }
        }
    }
}

struct AircraftPickerCard: View {
    let aircraft: Aircraft
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(aircraft.tailNumber)
                    .font(.headline)
                Text(aircraft.type)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f", aircraft.tachCurrent ?? 0))
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.brandBlue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.brandBlue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
