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

    static func policyFeed(body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/ml/content/policy-feed", method: .post, body: body)
    }

    private static let baseURL = NetworkConfiguration.mlServiceBaseURL
}
