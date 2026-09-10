import Foundation

nonisolated struct NewsroomMarketQuote: Equatable, Sendable {
    let changePercent: Double
    let asOf: Date
}

/// 공개 시세 요청에는 사용자 토큰/계좌 정보를 붙이지 않는다.
/// Yahoo chart의 1일 범위 previousClose는 직전 정규장 종가다.
actor NewsroomMarketQuoteRepository {
    private let session: URLSession
    private var cached: [String: (quote: NewsroomMarketQuote, expires: Date)] = [:]
    private var inFlight: [String: Task<NewsroomMarketQuote?, Never>] = [:]

    init(session: URLSession = .shared) { self.session = session }

    func fetch(ticker: String) async -> NewsroomMarketQuote? {
        let symbol = ticker.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        // 거래소가 없는 숫자 코드는 KS/KQ를 추측하지 않는다.
        guard !symbol.isEmpty, symbol.contains(where: { $0.isLetter }),
              symbol.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || ".-^=".contains($0)) }) else { return nil }
        if let value = cached[symbol], value.expires > Date() { return value.quote }
        if let task = inFlight[symbol] { return await task.value }
        let session = session
        let task = Task<NewsroomMarketQuote?, Never> {
            var components = URLComponents(string: "https://query1.finance.yahoo.com")!
            components.path = "/v8/finance/chart/\(symbol)"
            components.queryItems = [URLQueryItem(name: "range", value: "1d"),
                                     URLQueryItem(name: "interval", value: "1m"),
                                     URLQueryItem(name: "includePrePost", value: "false")]
            guard let url = components.url else { return nil }
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 6)
            request.setValue("egunHoldings/1.0", forHTTPHeaderField: "User-Agent")
            do {
                let (data, response) = try await session.data(for: request)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
                return try JSONDecoder().decode(NewsroomChartResponse.self, from: data).quote(for: symbol)
            } catch { return nil }
        }
        inFlight[symbol] = task
        let quote = await task.value
        inFlight[symbol] = nil
        if let quote { cached[symbol] = (quote, Date().addingTimeInterval(60)) }
        return quote
    }
}

nonisolated struct NewsroomChartResponse: Decodable {
    let chart: Chart
    struct Chart: Decodable { let result: [Result]? }
    struct Result: Decodable { let meta: Meta }
    struct Meta: Decodable {
        let symbol: String
        let regularMarketPrice: Double?
        let previousClose: Double?
        let chartPreviousClose: Double?
        let regularMarketTime: Double?
    }

    func quote(for symbol: String, now: Date = Date()) -> NewsroomMarketQuote? {
        guard let meta = chart.result?.first?.meta, meta.symbol.uppercased() == symbol.uppercased(),
              let current = meta.regularMarketPrice, current.isFinite, current > 0,
              let previous = meta.previousClose ?? meta.chartPreviousClose, previous.isFinite, previous > 0,
              let timestamp = meta.regularMarketTime, timestamp.isFinite else { return nil }
        let asOf = Date(timeIntervalSince1970: timestamp)
        // 주말/휴장 시 최근 거래일은 허용하되 장기 중단/오래된 응답은 오늘의 수치로 쓰지 않는다.
        guard now.timeIntervalSince(asOf) >= -300, now.timeIntervalSince(asOf) < 7 * 86_400 else { return nil }
        return NewsroomMarketQuote(changePercent: (current / previous - 1) * 100, asOf: asOf)
    }
}
