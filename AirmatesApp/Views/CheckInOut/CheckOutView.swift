import SwiftUI

struct CheckOutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var aircraft: [Aircraft] = []
    @State private var selectedAircraftId = ""
    @State private var tachOut = ""
    @State private var destination = ""
    @State private var expectedReturn = Date().addingTimeInterval(3600 * 3)
    @State private var isLoading = true
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Aircraft") {
                    if isLoading {
                        ProgressView()
                    } else {
                        Picker("Aircraft", selection: $selectedAircraftId) {
                            Text("Select...").tag("")
                            ForEach(aircraft.filter { $0.isAvailable }) { ac in
                                Text("\(ac.tailNumber) — \(ac.type) (Tach: \(String(format: "%.1f", ac.tachCurrent)))").tag(ac.id)
                            }
                        }
                    }
                }

                Section("Flight Info") {
                    HStack {
                        Text("Tach Out")
                        Spacer()
                        TextField("0.0", text: $tachOut)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    TextField("Destination (optional)", text: $destination)
                    DatePicker("Expected Return", selection: $expectedReturn, displayedComponents: [.date, .hourAndMinute])
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Check Out Aircraft")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Check Out") { checkOut() }
                        .disabled(selectedAircraftId.isEmpty || tachOut.isEmpty || isSubmitting)
                }
            }
            .onChange(of: selectedAircraftId) { _, newId in
                if let ac = aircraft.first(where: { $0.id == newId }) {
                    tachOut = String(format: "%.1f", ac.tachCurrent)
                }
            }
        }
        .task { await loadAircraft() }
    }

    private func loadAircraft() async {
        isLoading = true
        do {
            aircraft = try await APIClient.shared.get("/api/aircraft")
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func checkOut() {
        isSubmitting = true
        errorMessage = nil
        Task {
            do {
                struct CheckOutBody: Encodable {
                    let aircraftId: String
                    let tachOut: String
                    let destination: String?
                    let expectedReturn: String?
                }
                let formatter = ISO8601DateFormatter()
                let _: Checkout = try await APIClient.shared.post("/api/checkouts", body: CheckOutBody(
                    aircraftId: selectedAircraftId,
                    tachOut: tachOut,
                    destination: destination.isEmpty ? nil : destination,
                    expectedReturn: formatter.string(from: expectedReturn)
                ))
                onComplete()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}

struct CheckInView: View {
    let checkout: Checkout
    @Environment(\.dismiss) private var dismiss
    @State private var tachIn = ""
    @State private var fuelAdded = ""
    @State private var notes = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Aircraft") {
                    HStack {
                        Text(checkout.aircraft?.tailNumber ?? "Unknown")
                            .font(.headline)
                        Spacer()
                        Text("Tach Out: \(String(format: "%.1f", checkout.tachOut))")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Check In") {
                    HStack {
                        Text("Tach In")
                        Spacer()
                        TextField("0.0", text: $tachIn)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    if let tachInVal = Double(tachIn) {
                        HStack {
                            Text("Hobbs Time")
                            Spacer()
                            let hobbs = max(0, tachInVal - checkout.tachOut)
                            Text(String(format: "%.1f hrs", hobbs))
                                .foregroundColor(.brandBlue)
                                .bold()
                        }
                    }

                    HStack {
                        Text("Fuel Added (gal)")
                        Spacer()
                        TextField("0.0", text: $fuelAdded)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }

                Section("Notes") {
                    TextField("Any notes...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Check In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Check In") { checkIn() }
                        .disabled(tachIn.isEmpty || isSubmitting)
                }
            }
        }
    }

    private func checkIn() {
        isSubmitting = true
        errorMessage = nil
        Task {
            do {
                struct CheckInBody: Encodable {
                    let checkoutId: String
                    let tachIn: String
                    let fuelAdded: String?
                    let notes: String?
                }
                let _: CheckoutResponse = try await APIClient.shared.post("/api/checkouts", body: CheckInBody(
                    checkoutId: checkout.id,
                    tachIn: tachIn,
                    fuelAdded: fuelAdded.isEmpty ? nil : fuelAdded,
                    notes: notes.isEmpty ? nil : notes
                ))
                onComplete()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}
