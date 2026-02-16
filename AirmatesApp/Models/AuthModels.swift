import Foundation

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}

struct APIErrorResponse: Codable {
    let error: String
}
