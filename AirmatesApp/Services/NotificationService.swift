import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }

    func registerCategories() {
        let bookingReminder = UNNotificationCategory(
            identifier: "booking_reminder",
            actions: [
                UNNotificationAction(identifier: "view", title: "View Booking"),
                UNNotificationAction(identifier: "cancel", title: "Cancel", options: .destructive),
            ],
            intentIdentifiers: []
        )

        let checkoutReminder = UNNotificationCategory(
            identifier: "checkout_reminder",
            actions: [
                UNNotificationAction(identifier: "checkin", title: "Check In Now"),
            ],
            intentIdentifiers: []
        )

        let announcement = UNNotificationCategory(
            identifier: "announcement",
            actions: [
                UNNotificationAction(identifier: "view", title: "Read"),
                UNNotificationAction(identifier: "dismiss", title: "Dismiss"),
            ],
            intentIdentifiers: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            bookingReminder, checkoutReminder, announcement,
        ])
    }

    func uploadDeviceToken(_ token: Data) async {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()

        struct PushSubscription: Encodable {
            let deviceToken: String
            let platform: String
        }

        do {
            let _: [String: String] = try await APIClient.shared.post(
                "/api/push/subscribe",
                body: PushSubscription(deviceToken: tokenString, platform: "ios")
            )
        } catch {
            // Silently fail — push is optional
        }
    }

    func getPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
}
