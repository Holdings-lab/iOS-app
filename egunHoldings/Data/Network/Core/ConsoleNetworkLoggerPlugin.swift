import Foundation
@preconcurrency import Moya

nonisolated final class ConsoleNetworkLoggerPlugin: PluginType, @unchecked Sendable {
    nonisolated func willSend(_ request: RequestType, target _: TargetType) {
#if DEBUG
        guard let urlRequest = request.request else {
            print("[Network][Request] URLRequest could not be created.")
            return
        }

        let requestBody = Self.formattedPayload(from: urlRequest.httpBody) ?? "(empty)"
        let headers = Self.formattedHeaders(urlRequest.allHTTPHeaderFields)

        print(
            """
            [Network][Request]
            \(urlRequest.httpMethod ?? "UNKNOWN") \(urlRequest.url?.absoluteString ?? "(invalid url)")
            Headers: \(headers)
            Body:
            \(requestBody)
            """
        )
#endif
    }

    nonisolated func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
#if DEBUG
        switch result {
        case .success(let response):
            let responseBody = Self.formattedPayload(from: response.data) ?? "(empty)"

            print(
                """
                [Network][Response]
                \(response.request?.httpMethod ?? "UNKNOWN") \(response.request?.url?.absoluteString ?? target.baseURL.absoluteString)
                Status: \(response.statusCode)
                Body:
                \(responseBody)
                """
            )

        case .failure(let error):
            let requestDescription = error.response?.request?.url?.absoluteString ?? target.baseURL.appendingPathComponent(target.path).absoluteString
            let responseBody = Self.formattedPayload(from: error.response?.data) ?? "(empty)"
            let statusDescription = error.response.map { String($0.statusCode) } ?? "(no status)"

            print(
                """
                [Network][Error]
                \(error.response?.request?.httpMethod ?? "UNKNOWN") \(requestDescription)
                Status: \(statusDescription)
                Error: \(error.localizedDescription)
                Body:
                \(responseBody)
                """
            )
        }
#endif
    }

    private static func formattedHeaders(_ headers: [String: String]?) -> String {
        guard let headers, headers.isEmpty == false else {
            return "[]"
        }

        let redacted = headers.map { key, value in
            let normalizedKey = key.lowercased()
            if normalizedKey == "authorization" || normalizedKey.contains("secret") {
                return "\(key)=<redacted>"
            }

            return "\(key)=\(value)"
        }

        return redacted.sorted().joined(separator: ", ")
    }

    private static func formattedPayload(from data: Data?) -> String? {
        guard let data, data.isEmpty == false else {
            return nil
        }

        if
            let jsonObject = try? JSONSerialization.jsonObject(with: data),
            let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
            let prettyString = String(data: prettyData, encoding: .utf8)
        {
            return prettyString
        }

        return String(data: data, encoding: .utf8) ?? "<\(data.count) bytes>"
    }
}
