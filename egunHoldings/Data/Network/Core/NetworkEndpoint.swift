import Foundation

nonisolated enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

nonisolated enum AuthorizationRequirement: Sendable {
    case none
    case bearerToken
}

nonisolated struct Endpoint: Sendable {
    let baseURL: URL
    let path: String
    let queryItems: [URLQueryItem]
    let method: HTTPMethod
    let headers: [String: String]
    let body: Data?
    let authorizationRequirement: AuthorizationRequirement

    init(
        baseURL: URL,
        path: String,
        queryItems: [URLQueryItem] = [],
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        body: Data? = nil,
        authorizationRequirement: AuthorizationRequirement = .none
    ) {
        self.baseURL = baseURL
        self.path = path
        self.queryItems = queryItems
        self.method = method
        self.headers = Self.defaultHeaders(hasBody: body != nil).merging(headers) { _, explicit in
            explicit
        }
        self.body = body
        self.authorizationRequirement = authorizationRequirement
    }

    var queryParameters: [String: Any] {
        Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })
    }

    private static func defaultHeaders(hasBody: Bool) -> [String: String] {
        var headers = ["Accept": "application/json"]

        if hasBody {
            headers["Content-Type"] = "application/json"
        }

        return headers
    }
}
