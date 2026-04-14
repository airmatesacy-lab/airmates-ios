import SwiftUI

struct CheckInSheet: View {
    let checkout: Checkout
    @Bindable var viewModel: FlyViewModel
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isSubmitting = false
    @State private var showTachConfirmation = false

    var tachDelta: Double? {
        guard let tachIn = Double(viewModel.tachIn) else { return nil }
        return max(0, tachIn - checkout.tachOut)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Aircraft info
                    HStack {
                        VStack(alignment: .leading) {
                            Text(checkout.aircraft?.tailNumber ?? "Aircraft")
                                .font(.title3.bold())
                            Text(checkout.aircraft?.type ?? "")
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(meterLabel) Out")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f", checkout.tachOut))
                                .font(.headline.monospaced())
                        }
                    }
                    .padding(.horizontal)

                    // Meter In
                    TachPadView(value: $viewModel.tachIn, label: "\(meterLabel) In")
                        .padding(.horizontal)

                    // Flight time display
                    if let delta = tachDelta {
                        HStack {
                            Text("Flight Time")
                                .font(.headline)
                            Spacer()
                            Text(String(format: "%.1f hrs", delta))
                                .font(.title2.bold().monospaced())
                                .foregroundColor(.brandBlue)
                        }
                        .padding()
                        .background(Color.brandBlue.opacity(0.05))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }

                    // Flight type — preloaded from the linked booking when available
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Flight Type")
                                .font(.headline)
                            if checkout.booking != nil {
                                Text("from booking")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(4)
                            }
                        }
                        Picker("Type", selection: $viewModel.flightType) {
                            Text("Solo").tag("SOLO")
                            Text("Dual").tag("DUAL")
                            Text("Maintenance").tag("MAINTENANCE")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)

                    // Fuel
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Fuel Added (gal)")
                            .font(.headline)
                        TextField("0.0", text: $viewModel.fuelAdded)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal)

                    // Landing counters
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Landings & Approaches")
                            .font(.headline)
                            .padding(.horizontal)
                        LandingCounterView(
                            dayLandings: $viewModel.dayLandings,
                            nightLandings: $viewModel.nightLandings,
                            fullStopDay: $viewModel.fullStopDay,
                            fullStopNight: $viewModel.fullStopNight,
                            instrumentApproaches: $viewModel.instrumentApproaches,
                            holds: $viewModel.holds
                        )
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        TextField("Any notes...", text: $viewModel.notes, axis: .vertical)
                            .lineLimit(2...4)
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

                    // Check In button
                    Button {
                        if viewModel.needsTachConfirmation {
                            showTachConfirmation = true
                        } else {
                            performCheckIn()
                        }
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            }
                            Text("Complete Check-In")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canCheckIn ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!canCheckIn || isSubmitting)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Check In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Confirm Flight Time", isPresented: $showTachConfirmation) {
                Button("Confirm Check-In") { performCheckIn() }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let delta = tachDelta {
                    Text("Tach Out: \(String(format: "%.1f", checkout.tachOut)) \u{2192} Tach In: \(viewModel.tachIn)\nFlight time: \(String(format: "%.1f", delta)) hours\n\nIs this correct?")
                }
            }
            .task {
                // Preload flight type from the booking linked to this checkout.
                // Backend auto-links bookings on check-out and returns the nested
                // booking in the /api/checkouts response (see Checkout.booking).
                // No override if backend hasn't shipped yet — booking will be nil
                // and we fall through to the viewModel's default ("SOLO").
                if let bookingType = checkout.booking?.type {
                    viewModel.flightType = bookingType
                }
            }
        }
    }

    var meterLabel: String {
        checkout.meterType == "HOBBS" ? "Hobbs" : "Tach"
    }

    var canCheckIn: Bool {
        guard let tachIn = Double(viewModel.tachIn),
              tachIn > 0,
              tachIn >= checkout.tachOut,
              tachIn <= AppConstants.tachMaxValue else { return false }
        return true
    }

    func performCheckIn() {
        isSubmitting = true
        Task {
            let success = await viewModel.checkIn()
            isSubmitting = false
            if success {
                onComplete()
                dismiss()
            }
        }
    }
}
