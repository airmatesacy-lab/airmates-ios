import SwiftUI

struct ProfileEditView: View {
    let user: User
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var phone: String
    @State private var addressLine1: String
    @State private var addressLine2: String
    @State private var city: String
    @State private var state: String
    @State private var zip: String
    @State private var emergencyName: String
    @State private var emergencyPhone: String
    @State private var emergencyRelation: String
    @State private var pilotCertNumber: String
    @State private var medicalClass: String
    @State private var medicalExpiry: String
    @State private var totalHours: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(user: User, onSave: @escaping () -> Void) {
        self.user = user
        self.onSave = onSave
        _name = State(initialValue: user.name)
        _phone = State(initialValue: user.phone ?? "")
        _addressLine1 = State(initialValue: user.addressLine1 ?? "")
        _addressLine2 = State(initialValue: user.addressLine2 ?? "")
        _city = State(initialValue: user.city ?? "")
        _state = State(initialValue: user.state ?? "")
        _zip = State(initialValue: user.zip ?? "")
        _emergencyName = State(initialValue: user.emergencyName ?? "")
        _emergencyPhone = State(initialValue: user.emergencyPhone ?? "")
        _emergencyRelation = State(initialValue: user.emergencyRelation ?? "")
        _pilotCertNumber = State(initialValue: user.pilotCertNumber ?? "")
        _medicalClass = State(initialValue: user.medicalClass ?? "")
        _medicalExpiry = State(initialValue: user.medicalExpiry ?? "")
        _totalHours = State(initialValue: user.totalHours.map { String($0) } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Info") {
                    TextField("Name", text: $name)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }

                Section("Address") {
                    TextField("Address Line 1", text: $addressLine1)
                    TextField("Address Line 2", text: $addressLine2)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("ZIP", text: $zip)
                        .keyboardType(.numberPad)
                }

                Section("Emergency Contact") {
                    TextField("Name", text: $emergencyName)
                    TextField("Phone", text: $emergencyPhone)
                        .keyboardType(.phonePad)
                    TextField("Relationship", text: $emergencyRelation)
                }

                Section("Pilot Info") {
                    TextField("Certificate Number", text: $pilotCertNumber)
                    Picker("Medical Class", selection: $medicalClass) {
                        Text("None").tag("")
                        Text("First Class").tag("First")
                        Text("Second Class").tag("Second")
                        Text("Third Class").tag("Third")
                        Text("BasicMed").tag("BasicMed")
                    }
                    TextField("Total Hours", text: $totalHours)
                        .keyboardType(.decimalPad)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveProfile() }
                        .disabled(isSaving || name.isEmpty)
                }
            }
        }
    }

    private func saveProfile() {
        isSaving = true
        errorMessage = nil
        Task {
            do {
                struct ProfileBody: Encodable {
                    let name: String
                    let phone: String
                    let addressLine1: String
                    let addressLine2: String
                    let city: String
                    let state: String
                    let zip: String
                    let emergencyName: String
                    let emergencyPhone: String
                    let emergencyRelation: String
                    let pilotCertNumber: String
                    let medicalClass: String
                    let totalHours: String
                }
                let _: User = try await APIClient.shared.patch("/api/profile", body: ProfileBody(
                    name: name, phone: phone,
                    addressLine1: addressLine1, addressLine2: addressLine2,
                    city: city, state: state, zip: zip,
                    emergencyName: emergencyName, emergencyPhone: emergencyPhone, emergencyRelation: emergencyRelation,
                    pilotCertNumber: pilotCertNumber, medicalClass: medicalClass,
                    totalHours: totalHours
                ))
                onSave()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
