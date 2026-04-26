import Foundation

nonisolated struct ExchangeRateQuote: Sendable {
    let usdToKrw: Double
    let fetchedAt: Date
}

protocol ExchangeRateProviding {
    func fetchUSDKRW() async throws -> ExchangeRateQuote
}

nonisolated enum ExchangeRateError: Error, Sendable {
    case invalidURL
    case invalidResponse
}

nonisolated struct LiveExchangeRateProvider: ExchangeRateProviding {
    private struct FrankfurterResponse: Decodable, Sendable {
        let rates: [String: Double]
    }

    private let apiClient: APIClient
    private let baseURL = URL(string: "https://api.frankfurter.app")!

    init(apiClient: APIClient = APIClientFactory.makeDefault()) {
        self.apiClient = apiClient
    }

    func fetchUSDKRW() async throws -> ExchangeRateQuote {
        let decoded = try await apiClient.request(
            Endpoint(
                baseURL: baseURL,
                path: "/latest",
                queryItems: [
                    URLQueryItem(name: "from", value: "USD"),
                    URLQueryItem(name: "to", value: "KRW"),
                ]
            ),
            as: FrankfurterResponse.self
        )
        guard let rate = decoded.rates["KRW"], rate > 0 else {
            throw ExchangeRateError.invalidResponse
        }

        return ExchangeRateQuote(usdToKrw: rate, fetchedAt: Date())
    }
}

nonisolated struct MockExchangeRateProvider: ExchangeRateProviding {
    let fallbackRate: Double

    init(fallbackRate: Double = 1_375) {
        self.fallbackRate = fallbackRate
    }

    func fetchUSDKRW() async throws -> ExchangeRateQuote {
        ExchangeRateQuote(usdToKrw: fallbackRate, fetchedAt: Date())
    }
}
