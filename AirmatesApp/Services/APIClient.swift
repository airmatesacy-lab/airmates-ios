import Foundation

enum APIError: Error, LocalizedError {
    case unauthorized
    case serverError(String)
    case networkError(Error)
    case decodingError(Error)
    case conflict(String, Data?)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Session expired. Please log in again."
        case .serverError(let msg): return msg
        case .networkError(let err): return err.localizedDescription
        case .decodingError(let err): return "Data error: \(err.localizedDescription)"
        case .conflict(let msg, _): return msg
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
        case 409:
            let errorMsg = (try? decoder.decode(Models.APIError.self, from: data))?.error ?? "Conflict"
            throw APIError.conflict(errorMsg, data)
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
}

// Namespace for API error response
private enum Models {
    struct APIError: Decodable {
        let error: String
    }
}
