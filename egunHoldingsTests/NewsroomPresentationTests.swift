import Combine
import Foundation
import Testing
import UIKit
@testable import egunHoldings

@MainActor
struct NewsroomPresentationTests {
    @Test("뉴스가 있는 종목을 비중순으로 모으고 Quiet은 맨 아래에 둔다")
    func groupsAndSortsHoldings() {
        let original = NewsroomDigestMockData.calmMixed
        let scrambled = original.replacingHoldings(Array(original.holdings.reversed()))
        #expect(scrambled.sortedHoldings.map(\.ticker) == ["AAPL", "NVDA", "MSFT", "QQQ"])
        #expect(scrambled.sortedHoldings.last?.weightPercent == 35)
    }

    @Test("오늘 등락은 서버가 준 값만 쓰고 없으면 미확인으로 둔다")
    func usesServerSuppliedDailyChange() throws {
        let hero = Data(#"{"ticker":"QQQ","name":"QQQ","weightPct":7.12,"briefingType":"Hero","dailyChangePct":-1.25}"#.utf8)
        let holding = try JSONDecoder().decode(NewsroomHoldingBriefingDTO.self, from: hero).toDomain()
        #expect(holding.dailyChangePercent == -1.25)
        #expect(holding.weightPercent == 7.12)
        #expect(NewsroomPercentFormat.weight(holding.weightPercent) == "7.12")

        let quiet = Data(#"{"ticker":"XLV","name":"XLV","weightPct":2,"briefingType":"Quiet"}"#.utf8)
        #expect(try JSONDecoder().decode(NewsroomHoldingBriefingDTO.self, from: quiet).toDomain().dailyChangePercent == nil)
    }

    @Test("상세 헤더의 등락도 상세 응답의 값을 그대로 쓴다")
    func usesServerSuppliedDetailChange() throws {
        let data = Data(#"{"ticker":"XLE","name":"SPDR ENERGY SELECT SECTOR","logoUrl":null,"dailyChangePct":0.3,"weightPct":1.3}"#.utf8)
        let stock = try JSONDecoder().decode(NewsroomStockMetaDTO.self, from: data).toDomain()
        #expect(stock.dailyChangePercent == 0.3)
        #expect(stock.weightPercent == 1.3)
    }

    @Test("목록 카드는 요약 전문 대신 첫 문장만 보여준다")
    func showsOnlyFirstSentenceOfSummary() {
        let body = "8월 28일 자산운용사 젝스는 QQQ가 8연속 하락장을 기록했다고 분석했다. 한편 마블 테크놀로지는 7% 하락했다."
        #expect(NewsroomSummaryText.firstSentence(of: body) == "8월 28일 자산운용사 젝스는 QQQ가 8연속 하락장을 기록했다고 분석했다.")
        // 소수점과 약어는 문장 끝이 아니다.
        #expect(NewsroomSummaryText.firstSentence(of: "QQQ는 7.30% 비중이다. 다음 문장.") == "QQQ는 7.30% 비중이다.")
        #expect(NewsroomSummaryText.firstSentence(of: "  마침표 없는 한 문장  ") == "마침표 없는 한 문장")
    }

    @Test("Quiet 행은 상세 기사 대신 정적 안내문을 쓴다")
    func usesStaticQuietRowCopy() {
        #expect(NewsroomTickerQuietRow.titleText == "특이사항 없음")
        #expect(NewsroomTickerQuietRow.subtitleText == "계속 지켜보고 있어요")
    }

    @Test("이미지 URL 결측값을 버리고 출처의 유효한 이미지를 사용한다")
    func filtersImageURLs() throws {
        for value in ["nan", "NaN", "null", "", " /image.jpg ", "file:///image.jpg", "https://"] {
            #expect(NewsroomRemoteURL.parse(value) == nil)
        }
        let data = Data(#"{"stock":{"ticker":"QQQ","name":"QQQ"},"headline":"기사","imageUrl":"nan","sources":[{"title":"출처","publisher":"신문","thumbnailUrl":" https://example.com/article.jpg ","url":"https://example.com/article"}]}"#.utf8)
        let detail = try JSONDecoder().decode(NewsroomTickerDetailResponseDTO.self, from: data).toDomain()
        #expect(detail.imageURL == nil)
        #expect(detail.imageCandidates.map(\.absoluteString) == ["https://example.com/article.jpg"])
        #expect(detail.primaryArticleURL?.absoluteString == "https://example.com/article")
    }

    @Test("상세의 동시 진입/재진입은 요청을 공유하고 갱신/날짜 변경 때 다시 조회한다")
    func cachesDetailsByDateAndTicker() async throws {
        let source = DetailCountingRepository()
        let repository = CachedNewsroomDigestRepository(repository: source)
        async let first = repository.fetchDetail(ticker: " aapl ", briefingDate: nil)
        async let second = repository.fetchDetail(ticker: "AAPL", briefingDate: nil)
        _ = try await (first, second)
        _ = try await repository.fetchDetail(ticker: "AAPL", briefingDate: nil)
        #expect(await source.count == 1)
        _ = try await repository.fetchDetail(ticker: "AAPL", briefingDate: "2026-09-08")
        #expect(await source.count == 2)
        await repository.invalidateBriefing()
        _ = try await repository.fetchDetail(ticker: "AAPL", briefingDate: nil)
        #expect(await source.count == 3)
    }

    @Test("자산 갱신이 끼어들어도 열려 있는 상세 요청은 끝까지 간다")
    func keepsOpenDetailRequestAliveThroughInvalidation() async throws {
        // 잔고가 갱신되면 Today 탭이 invalidateNews() → invalidateBriefing()을 호출한다.
        // 그때 마침 상세를 열어 둔 사용자의 요청까지 취소되면 안 된다.
        let source = GatedDetailRepository()
        let repository = CachedNewsroomDigestRepository(repository: source)
        async let opened = repository.fetchDetail(ticker: "AAPL", briefingDate: nil)

        await source.waitUntilRequestStarted()
        await repository.invalidateBriefing()
        await source.release()
        #expect(try await opened.headline.isEmpty == false)

        // 무효화 뒤의 진입은 캐시를 재사용하지 않고 새로 조회한다.
        await source.release()
        _ = try await repository.fetchDetail(ticker: "AAPL", briefingDate: nil)
        #expect(await source.count == 2)
    }

    @Test("상세 실패는 캐시하지 않아 다음 진입에서 재시도한다")
    func retriesDetailFailure() async throws {
        let source = DetailCountingRepository(failFirst: true)
        let repository = CachedNewsroomDigestRepository(repository: source)
        do {
            _ = try await repository.fetchDetail(ticker: "AAPL", briefingDate: nil)
            Issue.record("첫 상세 요청은 실패해야 한다")
        } catch {}
        _ = try await repository.fetchDetail(ticker: "AAPL", briefingDate: nil)
        #expect(await source.count == 2)
    }

    @Test("이미지 실패 시 다음 썸네일을 읽고 재표시 때는 네트워크 없이 재사용한다")
    func fallsBackAndCachesImages() async {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [NewsroomImageURLProtocol.self]
        let loader = NewsroomImageLoader(session: URLSession(configuration: configuration))
        let badURL = URL(string: "https://example.com/missing.png")!
        let goodURL = URL(string: "https://example.com/image.png")!
        let first = await loader.image(urls: [badURL, goodURL])
        let second = await loader.image(urls: [badURL, goodURL])
        #expect(first != nil)
        #expect(first === second)
    }

    @Test("목록 이미지 선조회는 직접 URL만 받아 상세 화면의 캐시에 재사용한다")
    func preloadsDirectImages() async {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [NewsroomImageURLProtocol.self]
        let loader = NewsroomImageLoader(session: URLSession(configuration: configuration))
        let imageURL = URL(string: "https://example.com/image.png")!
        await loader.preload(urls: [imageURL])
        let loaded = await loader.image(urls: [imageURL])
        #expect(loaded != nil)
    }

    @Test("선행 출처 피드는 서버와 같은 종목 필터를 쓰고 기사 사진을 섞지 않는다")
    func matchesEarlySources() throws {
        let json = #"{"cards":[{"newsId":"1","title":"UPS news","date":"2026-09-10","link":"https://example.com/ups","thumbnailUrl":"nan","assetSignals":[{"ticker":"QQQ"}]},{"newsId":"2","title":"Apple news","date":"2026-09-09","link":"https://example.com/apple","thumbnailUrl":"https://example.com/apple.png","assetSignals":[{"ticker":"QQQ"}]},{"newsId":"3","title":"Daily ETF Flows: XLE","date":"2026-09-10","link":"https://example.com/xle"}]}"#
        let feed = try JSONDecoder().decode(NewsroomSourceFeedDTO.self, from: Data(json.utf8))
        #expect(feed.sources(for: " qqq ", on: "2026-09-10").map(\.newsId) == ["1"])
        #expect(feed.sources(for: "XLE", on: "2026-09-10").map(\.newsId) == ["3"])
        #expect(feed.sources(for: "XLV", on: "2026-09-10").isEmpty)
        let model = NewsroomTickerDetail(stock: NewsroomDigestMockData.appleDetail.stock,
            headline: "UPS news", imageURL: nil, aiJudgement: nil, summaryBody: nil, findings: [],
            sources: feed.sources(for: "QQQ", on: "2026-09-10"), asOfAt: nil, aiNotice: nil)
        #expect(model.imageCandidates.isEmpty)
        #expect(model.primaryArticleURL?.absoluteString == "https://example.com/ups")
        let sourceEndpoint = BackendEndpoint.newsroomSourceFeed(date: "2026-09-10")
        #expect(sourceEndpoint.queryItems.map(\.name) == ["limit", "dateFrom", "dateTo"])
        #expect(sourceEndpoint.queryItems.map(\.value) == ["50", "2026-09-10", "2026-09-10"])
        if case .bearerToken = sourceEndpoint.authorizationRequirement {
            Issue.record("공개 원문 조회에 사용자 토큰이 필요하면 안 된다")
        }
    }

    @Test("상세 분석이 지연돼도 원문 출처는 먼저 표시할 수 있다")
    func publishesSourcesBeforeDetail() async throws {
        let source = SlowDetailWithEarlySources()
        let model = NewsroomTickerDetailViewModel(holding: NewsroomDigestMockData.calmMixed.holdings[0], repository: source)
        model.load()
        // 네트워크 대신 제어된 continuation으로 완료 순서를 재현한다.
        await source.waitForSources()
        for await sources in model.$earlySources.values {
            if !sources.isEmpty { break }
        }
        #expect(model.earlySources.first?.newsId == "early")
        #expect(model.detail == nil)
        #expect(model.isLoading)
        await source.finishDetail()
    }

    @Test("목록에 들어오면 상세로 열 수 있는 보유 종목만 미리 받는다")
    func prefetchesOnlyInteractiveHoldingsOnLoad() async throws {
        let source = PrefetchRecordingRepository()
        let model = NewsroomDigestViewModel(repository: CachedNewsroomDigestRepository(repository: source))
        model.load()

        let tickers = await source.waitForDetails(count: 3)
        #expect(Set(tickers) == ["AAPL", "NVDA", "MSFT"])
        #expect(!tickers.contains("QQQ"))

        // 카드를 눌러 상세로 들어갈 때는 이미 받아둔 값을 쓰고 새 요청을 보내지 않는다.
        let holding = try #require(NewsroomDigestMockData.calmMixed.holdings.first)
        let detailModel = model.makeDetailViewModel(for: holding)
        detailModel.load()
        for await detail in detailModel.$detail.values {
            if detail != nil { break }
        }
        #expect(await source.detailTickers.count == 3)
    }
}

/// 목록 진입이 어떤 종목의 상세를 미리 받는지 기록한다.
private actor PrefetchRecordingRepository: NewsroomDigestRepositoryProtocol {
    private(set) var detailTickers: [String] = []
    private var waiter: (count: Int, continuation: CheckedContinuation<Void, Never>)?

    func fetchBriefing(briefingDate: String?) async throws -> NewsroomBriefing {
        await NewsroomDigestMockData.calmMixed
    }

    func fetchDetail(ticker: String, briefingDate: String?) async throws -> NewsroomTickerDetail {
        detailTickers.append(ticker)
        if let waiter, detailTickers.count >= waiter.count {
            self.waiter = nil
            waiter.continuation.resume()
        }
        return await NewsroomDigestMockData.appleDetail
    }

    func waitForDetails(count: Int) async -> [String] {
        if detailTickers.count < count {
            await withCheckedContinuation { waiter = (count, $0) }
        }
        return detailTickers
    }
}

private actor DetailCountingRepository: NewsroomDigestRepositoryProtocol {
    private(set) var count = 0
    let failFirst: Bool
    init(failFirst: Bool = false) { self.failFirst = failFirst }
    func fetchBriefing(briefingDate: String?) async throws -> NewsroomBriefing {
        await NewsroomDigestMockData.calmMixed
    }
    func fetchDetail(ticker: String, briefingDate: String?) async throws -> NewsroomTickerDetail {
        count += 1
        if count == 1 && failFirst { throw URLError(.timedOut) }
        try await Task.sleep(for: .milliseconds(20))
        return await NewsroomDigestMockData.appleDetail
    }
}

/// 요청이 실제로 서버까지 나간 순간을 테스트가 붙잡을 수 있게 한 스텁.
/// 진행 중인 요청에 무효화가 끼어드는 순서를 타이밍에 기대지 않고 재현한다.
private actor GatedDetailRepository: NewsroomDigestRepositoryProtocol {
    private(set) var count = 0
    private var started: CheckedContinuation<Void, Never>?
    private var gate: CheckedContinuation<Void, Never>?
    private var pendingRelease = false

    func fetchBriefing(briefingDate: String?) async throws -> NewsroomBriefing {
        await NewsroomDigestMockData.calmMixed
    }

    func fetchDetail(ticker: String, briefingDate: String?) async throws -> NewsroomTickerDetail {
        count += 1
        started?.resume()
        started = nil
        if pendingRelease {
            pendingRelease = false
        } else {
            await withCheckedContinuation { gate = $0 }
        }
        try Task.checkCancellation()
        return await NewsroomDigestMockData.appleDetail
    }

    func waitUntilRequestStarted() async {
        guard count == 0 else { return }
        await withCheckedContinuation { started = $0 }
    }

    /// 대기 중인 요청을 풀어 준다. 아직 시작 전이면 다음 요청이 그냥 통과한다.
    func release() {
        if let gate {
            self.gate = nil
            gate.resume()
        } else {
            pendingRelease = true
        }
    }
}

private final class NewsroomImageURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let success = request.url?.lastPathComponent == "image.png"
        let response = HTTPURLResponse(url: request.url!, statusCode: success ? 200 : 404, httpVersion: nil,
                                       headerFields: ["Content-Type": "image/png"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if success {
            // 1x1 PNG fixture, independent of the remote network.
            client?.urlProtocol(self, didLoad: Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP438DwHwAGgAJ/EEwb4QAAAABJRU5ErkJggg==")!)
        }
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

private actor SlowDetailWithEarlySources: NewsroomDigestRepositoryProtocol {
    private var detailContinuation: CheckedContinuation<NewsroomTickerDetail, Never>?
    private var detailReleased = false
    private var sourcesReturned = false
    private var sourcesContinuation: CheckedContinuation<Void, Never>?
    func fetchBriefing(briefingDate: String?) async throws -> NewsroomBriefing { NewsroomDigestMockData.calmMixed }
    func fetchDetail(ticker: String, briefingDate: String?) async throws -> NewsroomTickerDetail {
        if detailReleased { return NewsroomDigestMockData.appleDetail }
        return await withCheckedContinuation { detailContinuation = $0 }
    }
    func fetchSources(ticker: String) async throws -> [NewsroomSourceItem] {
        sourcesReturned = true
        sourcesContinuation?.resume()
        sourcesContinuation = nil
        return [NewsroomSourceItem(newsId: "early", title: "원문", publisher: "신문", publishedAtRaw: nil,
                                   thumbnailURL: nil, url: URL(string: "https://example.com/article"))]
    }
    func waitForSources() async {
        if sourcesReturned { return }
        await withCheckedContinuation { sourcesContinuation = $0 }
    }
    func finishDetail() {
        detailReleased = true
        detailContinuation?.resume(returning: NewsroomDigestMockData.appleDetail)
        detailContinuation = nil
    }
}
