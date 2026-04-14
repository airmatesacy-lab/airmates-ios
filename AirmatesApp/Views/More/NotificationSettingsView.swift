import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var pushEnabled = false
    @State private var emailEnabled = true
    @State private var smsEnabled = false
    @State private var pushPermissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var isSaving = false
    @State private var showSaved = false

    var body: some View {
        List {
            Section {
                Toggle("Push Notifications", isOn: $pushEnabled)
                    .onChange(of: pushEnabled) { _, newValue in
                        if newValue { requestPushPermission() }
                        savePreferences()
                    }

                if pushPermissionStatus == .denied {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Push notifications are disabled in iOS Settings. Tap to open Settings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .onTapGesture {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            } header: {
                Text("Push")
            } footer: {
                Text("Receive booking reminders, checkout alerts, and club announcements on your device.")
            }

            Section {
                Toggle("Email Notifications", isOn: $emailEnabled)
                    .onChange(of: emailEnabled) { _, _ in savePreferences() }
            } header: {
                Text("Email")
            } footer: {
                Text("Receive notifications via email at \(appState.currentUser?.email ?? "your email").")
            }

            Section {
                Toggle("SMS Notifications", isOn: $smsEnabled)
                    .onChange(of: smsEnabled) { _, _ in savePreferences() }
            } header: {
                Text("SMS")
            } footer: {
                if let phone = appState.currentUser?.phone, !phone.isEmpty {
                    Text("Receive text messages at \(phone). Standard messaging rates may apply.")
                } else {
                    Text("Add a phone number to your profile to enable SMS notifications.")
                }
            }

            if showSaved {
                Section {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Preferences saved")
                            .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .task {
            await loadPreferences()
        }
    }

    func loadPreferences() async {
        // Check push permission status
        pushPermissionStatus = await NotificationService.shared.getPermissionStatus()
        pushEnabled = pushPermissionStatus == .authorized

        // Load user preferences from profile
        if let user = appState.currentUser {
            emailEnabled = true // Default on
            smsEnabled = user.smsOptIn == true
        }
    }

    func requestPushPermission() {
        Task {
            let granted = await NotificationService.shared.requestPermission()
            pushEnabled = granted
            pushPermissionStatus = await NotificationService.shared.getPermissionStatus()
        }
    }

    func savePreferences() {
        isSaving = true
        Task {
            struct NotifPrefs: Encodable {
                let smsOptIn: Bool
            }
            do {
                let _: User = try await APIClient.shared.patch(
                    "/api/profile",
                    body: NotifPrefs(smsOptIn: smsEnabled)
                )
                showSaved = true
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                showSaved = false
            } catch {}
            isSaving = false
        }
    }
}
