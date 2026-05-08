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

    func refreshToken(targetOrgId: String? = nil) async throws -> AuthResponse {
        // The refresh endpoint uses the existing token in the Authorization header.
        // Optional targetOrgId lets the user switch active org without re-login —
        // backend verifies membership in the target org before issuing the JWT.
        let body: SwitchOrgRequest? = targetOrgId.map { SwitchOrgRequest(targetOrgId: $0) }
        let response: AuthResponse = try await api.post("/api/auth/mobile/refresh", body: body)
        // Save the new token
        KeychainManager.shared.saveToken(response.token)
        return response
    }
}

private struct SwitchOrgRequest: Encodable {
    let targetOrgId: String
}
