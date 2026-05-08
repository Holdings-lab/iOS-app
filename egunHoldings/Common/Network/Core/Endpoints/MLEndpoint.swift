import Foundation

nonisolated enum MLEndpoint {
    static func health() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/ml/health")
    }

    static func runCrawler() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/ml/crawl/run", method: .post, body: NetworkJSONCoding.encodeEmptyJSONObject())
    }

    static func runPredict() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/ml/predict/run", method: .post, body: NetworkJSONCoding.encodeEmptyJSONObject())
    }

    static func predictResult() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/ml/predict/result")
    }

    static func pipeline() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/ml/pipeline", method: .post, body: NetworkJSONCoding.encodeEmptyJSONObject())
    }

    static func policyFeed(
        userId: Int64? = nil,
        limit: Int? = nil,
        category: String? = nil,
        dateFrom: String? = nil,
        dateTo: String? = nil
    ) -> Endpoint {
        Endpoint(
            baseURL: baseURL,
            path: "/ml/content/policy-feed",
            queryItems: policyFeedQuery(userId: userId, limit: limit, category: category, dateFrom: dateFrom, dateTo: dateTo)
        )
    }

    private static let baseURL = NetworkConfiguration.mlServiceBaseURL

    private static func policyFeedQuery(
        userId: Int64?,
        limit: Int?,
        category: String?,
        dateFrom: String?,
        dateTo: String?
    ) -> [URLQueryItem] {
        [
            userId.map { URLQueryItem(name: "userId", value: String($0)) },
            limit.map { URLQueryItem(name: "limit", value: String($0)) },
            queryItem(name: "category", value: category),
            queryItem(name: "dateFrom", value: dateFrom),
            queryItem(name: "dateTo", value: dateTo),
        ].compactMap { $0 }
    }

    private static func queryItem(name: String, value: String?) -> URLQueryItem? {
        guard let value else {
            return nil
        }

        return URLQueryItem(name: name, value: value)
    }
}
