import Foundation

enum APIError: Error, LocalizedError {
    case unauthorized
    case serverError(String)
    case networkError(Error)
    case decodingError(Error)
    case conflict(String, Data?)
    case preconditionRequired(String, Data?)
    case forbidden(String)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Session expired. Please log in again."
        case .serverError(let msg): return msg
        case .networkError(let err): return err.localizedDescription
        case .decodingError(let err): return "Data error: \(err.localizedDescription)"
        case .conflict(let msg, _): return msg
        case .preconditionRequired(let msg, _): return msg
        case .forbidden(let msg): return msg
        }
    }
}

class APIClient {
    static let shared = APIClient()

    #if DEBUG
    var baseURL = "https://airmateswebsite2026.vercel.app"
    #else
    var baseURL = "https://airmateswebsite2026.vercel.app"
    #endif

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // Callback for 401s — set by AppState
    var onUnauthorized: (() -> Void)?

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)

        decoder = JSONDecoder()
        // Handle ISO 8601 dates with fractional seconds
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)

            let formatters: [DateFormatter] = [
                .iso8601WithFractionalSeconds,
                .iso8601,
            ]

            for formatter in formatters {
                if let date = formatter.date(from: dateStr) {
                    return date
                }
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateStr)"
            )
        }

        encoder = JSONEncoder()
    }

    // MARK: - Core Request

    func request<T: Decodable>(
        _ method: String,
        path: String,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        var urlComponents = URLComponents(string: "\(baseURL)\(path)")!
        if let queryItems {
            urlComponents.queryItems = queryItems
        }

        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Attach JWT
        if let token = KeychainManager.shared.getToken() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Encode body
        if let body {
            urlRequest.httpBody = try encoder.encode(body)
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("Invalid response")
        }

        // Handle error codes
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            DispatchQueue.main.async { self.onUnauthorized?() }
            throw APIError.unauthorized
        case 403:
            let errorMsg = (try? decoder.decode(Models.APIError.self, from: data))?.error ?? "Access denied"
            throw APIError.forbidden(errorMsg)
        case 409:
            let errorMsg = (try? decoder.decode(Models.APIError.self, from: data))?.error ?? "Conflict"
            throw APIError.conflict(errorMsg, data)
        case 428:
            let errorMsg = (try? decoder.decode(Models.APIError.self, from: data))?.error ?? "Action required"
            throw APIError.preconditionRequired(errorMsg, data)
        default:
            let errorMsg = (try? decoder.decode(Models.APIError.self, from: data))?.error ?? "Server error (\(httpResponse.statusCode))"
            throw APIError.serverError(errorMsg)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Convenience Methods

    func get<T: Decodable>(_ path: String, query: [URLQueryItem]? = nil) async throws -> T {
        try await request("GET", path: path, queryItems: query)
    }

    func post<T: Decodable>(_ path: String, body: Encodable? = nil) async throws -> T {
        try await request("POST", path: path, body: body)
    }

    func patch<T: Decodable>(_ path: String, body: Encodable? = nil) async throws -> T {
        try await request("PATCH", path: path, body: body)
    }

    func delete<T: Decodable>(_ path: String, query: [URLQueryItem]? = nil) async throws -> T {
        try await request("DELETE", path: path, queryItems: query)
    }

    func put<T: Decodable>(_ path: String, body: Encodable? = nil) async throws -> T {
        try await request("PUT", path: path, body: body)
    }

    // MARK: - Void Responses (for delete/ack endpoints that return non-model JSON)

    func requestVoid(
        _ method: String,
        path: String,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws {
        struct Empty: Decodable {}
        let _: Empty = try await request(method, path: path, body: body, queryItems: queryItems)
    }

    // MARK: - Retry Wrapper (does NOT modify existing request method)

    private var refreshTask: Task<String, Error>?

    /// Wraps `request()` with automatic token refresh on 401.
    /// Existing `request()` is untouched — this is additive only.
    func requestWithRetry<T: Decodable>(
        _ method: String,
        path: String,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        do {
            return try await request(method, path: path, body: body, queryItems: queryItems)
        } catch APIError.unauthorized {
            // Don't retry the refresh endpoint itself
            guard path != "/api/auth/mobile/refresh" else { throw APIError.unauthorized }

            // Attempt token refresh (serialize concurrent attempts)
            let newToken: String
            if let existingTask = refreshTask {
                newToken = try await existingTask.value
            } else {
                let task = Task<String, Error> {
                    defer { refreshTask = nil }
                    let response = try await AuthService.shared.refreshToken()
                    KeychainManager.shared.saveToken(response.token)
                    return response.token
                }
                refreshTask = task
                newToken = try await task.value
            }

            // Retry original request with new token (one attempt only)
            _ = newToken // token is now in Keychain, request() reads it
            return try await request(method, path: path, body: body, queryItems: queryItems)
        }
    }

    // MARK: - Retry Convenience Methods

    func getWithRetry<T: Decodable>(_ path: String, query: [URLQueryItem]? = nil) async throws -> T {
        try await requestWithRetry("GET", path: path, queryItems: query)
    }

    func postWithRetry<T: Decodable>(_ path: String, body: Encodable? = nil) async throws -> T {
        try await requestWithRetry("POST", path: path, body: body)
    }
}

// Namespace for API error response
private enum Models {
    struct APIError: Decodable {
        let error: String
    }
}
