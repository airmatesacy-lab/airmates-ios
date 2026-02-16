import Foundation

class AuthService {
    static let shared = AuthService()
    private let api = APIClient.shared

    private init() {}

    func login(email: String, password: String) async throws -> AuthResponse {
        let body = LoginRequest(email: email, password: password)
        let response: AuthResponse = try await api.post("/api/auth/mobile", body: body)
        return response
    }

    func refreshToken() async throws -> AuthResponse {
        // The refresh endpoint uses the existing token in the Authorization header
        let response: AuthResponse = try await api.post("/api/auth/mobile/refresh")
        // Save the new token
        KeychainManager.shared.saveToken(response.token)
        return response
    }
}
