import SwiftUI

@main
struct AirmatesApp: App {
    @State private var appState = AppState()

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
            }
        }
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
