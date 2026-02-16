import SwiftUI

struct AircraftDetailView: View {
    let aircraft: Aircraft
    @State private var showSquawkSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "airplane.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.brandBlue)
                    Text(aircraft.tailNumber)
                        .font(.largeTitle.bold())
                    Text(aircraft.type)
                        .font(.title3)
                        .foregroundColor(.secondary)
                    StatusBadge(status: aircraft.status)
                }
                .padding()

                // Info cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    infoCard("Tach", value: String(format: "%.1f", aircraft.tachCurrent), icon: "gauge")
                    infoCard("Rate", value: aircraft.hourlyRate.asCurrency + "/hr", icon: "dollarsign.circle")
                    if let year = aircraft.year {
                        infoCard("Year", value: "\(year)", icon: "calendar")
                    }
                    infoCard("Status", value: aircraft.status.replacingOccurrences(of: "_", with: " "), icon: "circle.fill")
                }

                // Squawks
                if let squawks = aircraft.squawks, !squawks.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Squawks")
                            .font(.headline)
                        ForEach(squawks) { squawk in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(squawk.description)
                                        .font(.subheadline)
                                    HStack {
                                        Text(squawk.category)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("•")
                                            .foregroundColor(.secondary)
                                        Text(squawk.reporter?.name ?? "")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                StatusBadge(status: squawk.status)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                }

                // Recent flights
                if let flights = aircraft.flights, !flights.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Flights")
                            .font(.headline)
                        ForEach(flights) { flight in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(flight.member?.name ?? "Unknown")
                                        .font(.subheadline)
                                    Text(flight.date.toShortDate())
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(flight.hobbsTime.asHours)
                                    .font(.subheadline.bold())
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                }

                // Maintenance
                if let maintenance = aircraft.maintenance?.filter({ !$0.completed }), !maintenance.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming Maintenance")
                            .font(.headline)
                        ForEach(maintenance) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.type)
                                        .font(.subheadline.bold())
                                    if let desc = item.description {
                                        Text(desc)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                if let due = item.dueDate {
                                    Text(due.toShortDate())
                                        .font(.caption)
                                        .foregroundColor(.brandOrange)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                }

                // Report Squawk button
                Button {
                    showSquawkSheet = true
                } label: {
                    Label("Report a Squawk", systemImage: "exclamationmark.triangle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brandOrange)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .background(Color.subtleBackground)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSquawkSheet) {
            SquawkFormSheet(aircraftId: aircraft.id, aircraftTail: aircraft.tailNumber)
        }
    }

    private func infoCard(_ title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.brandBlue)
                    .font(.caption)
                Spacer()
            }
            Text(value)
                .font(.subheadline.bold())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
    }
}

struct SquawkFormSheet: View {
    let aircraftId: String
    let aircraftTail: String
    @Environment(\.dismiss) private var dismiss
    @State private var description = ""
    @State private var category = "OTHER"
    @State private var priority = "LOW"
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    let categories = ["AIRFRAME", "ENGINE", "AVIONICS", "ELECTRICAL", "INTERIOR", "OTHER"]
    let priorities = ["LOW", "MEDIUM", "HIGH", "GROUNDING"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Aircraft") {
                    Text(aircraftTail)
                        .foregroundColor(.secondary)
                }

                Section("Details") {
                    TextField("Describe the issue...", text: $description, axis: .vertical)
                        .lineLimit(3...6)

                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat.replacingOccurrences(of: "_", with: " ").capitalized).tag(cat)
                        }
                    }

                    Picker("Priority", selection: $priority) {
                        ForEach(priorities, id: \.self) { p in
                            Text(p.capitalized).tag(p)
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Report Squawk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") { submitSquawk() }
                        .disabled(description.isEmpty || isSubmitting)
                }
            }
        }
    }

    private func submitSquawk() {
        isSubmitting = true
        errorMessage = nil
        Task {
            do {
                struct SquawkBody: Encodable {
                    let aircraftId: String
                    let description: String
                    let category: String
                    let priority: String
                }
                let _: Squawk = try await APIClient.shared.post("/api/squawks", body: SquawkBody(
                    aircraftId: aircraftId, description: description, category: category, priority: priority
                ))
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}
