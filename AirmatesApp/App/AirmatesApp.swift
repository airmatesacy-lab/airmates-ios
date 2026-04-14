import SwiftUI
import UserNotifications
import StripePaymentSheet

@main
struct AirmatesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var appState = AppState()

    init() {
        // Configure Stripe SDK once at launch — must happen before any
        // PaymentSheet is constructed. Safe to call from init since
        // StripeAPI.defaultPublishableKey is a simple global setter.
        StripeService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isCheckingAuth {
                    LaunchScreenView()
                } else if appState.isAuthenticated {
                    MainTabView()
                        .environment(appState)
                } else {
                    LoginView()
                        .environment(appState)
                }
            }
            .task {
                await appState.checkAuth()
                // Register notification categories
                NotificationService.shared.registerCategories()
                // Request notification permission if authenticated
                if appState.isAuthenticated {
                    _ = await NotificationService.shared.requestPermission()
                }
            }
            .onOpenURL { url in
                // Catch 3D Secure / bank verification return redirects
                let handled = StripeAPI.handleURLCallback(with: url)
                if !handled {
                    // Future: handle other deep links here (airmates://booking/xxx, etc.)
                }
            }
        }
    }
}

// MARK: - App Delegate for APNs

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task {
            await NotificationService.shared.uploadDeviceToken(deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Push registration failed — silently ignore (push is optional)
    }

    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .badge, .sound]
    }

    // Handle notification tap (just opens app for now — deep linking in v1.0 (3))
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        // Future: navigate to specific tab based on notification category
    }
}

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.brandDark.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "airplane")
                    .font(.system(size: 60))
                    .foregroundColor(.brandBlue)
                Text("Airmates")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                ProgressView()
                    .tint(.white)
            }
        }
    }
}
