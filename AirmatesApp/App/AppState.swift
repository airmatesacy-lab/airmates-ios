import SwiftUI

@Observable
class AppState {
    var isAuthenticated = false
    var isCheckingAuth = true
    var currentUser: User?
    var errorMessage: String?

    func checkAuth() async {
        isCheckingAuth = true
        defer { isCheckingAuth = false }

        guard KeychainManager.shared.getToken() != nil else {
            isAuthenticated = false
            return
        }

        do {
            let response = try await AuthService.shared.refreshToken()
            currentUser = response.user
            isAuthenticated = true
        } catch {
            // Token expired or invalid — clear and show login
            KeychainManager.shared.deleteToken()
            isAuthenticated = false
        }
    }

    func login(email: String, password: String) async throws {
        let response = try await AuthService.shared.login(email: email, password: password)
        KeychainManager.shared.saveToken(response.token)
        currentUser = response.user
        isAuthenticated = true
    }

    func logout() {
        KeychainManager.shared.deleteToken()
        currentUser = nil
        isAuthenticated = false
    }
}
