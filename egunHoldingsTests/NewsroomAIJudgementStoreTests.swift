import Foundation
import Testing
@testable import egunHoldings

/// `resolve(incoming:for:)`의 핵심 규칙 검증:
/// 서버가 매일 같은 값을 다시 보내든(daily-resend), 갱신일에만 보내든(sparse) 결과가 같아야 한다.
struct NewsroomAIJudgementStoreTests {
    private func judgement(headline: String, generatedAt: Date?) -> NewsroomAIJudgement {
        NewsroomAIJudgement(
            title: nil,
            headline: headline,
            reason: nil,
            alignment: nil,
            usedNewsURLs: [],
            disclaimer: nil,
            generatedAt: generatedAt
        )
    }

    private func makeStore() -> NewsroomAIJudgementStore {
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return NewsroomAIJudgementStore(defaults: defaults)
    }

    @Test("캐시가 없으면 응답을 그대로 채택하고 저장한다")
    func firstFetchAdoptsIncoming() async {
        let store = makeStore()
        let day1 = judgement(headline: "A", generatedAt: Date(timeIntervalSince1970: 1000))

        let resolved = await store.resolve(incoming: day1, for: "NVDA")
        let cached = await store.cached(for: "NVDA")

        #expect(resolved == day1)
        #expect(cached == day1)
    }

    @Test("옵션 A: 매일 같은 값이 다시 와도 갱신하지 않는다")
    func dailyResendOfSameValueIsNoOp() async {
        let store = makeStore()
        let day1 = judgement(headline: "A", generatedAt: Date(timeIntervalSince1970: 1000))
        _ = await store.resolve(incoming: day1, for: "NVDA")

        // 다음날에도 서버가 같은 generatedAt으로 같은 값을 다시 보냄
        let resolved = await store.resolve(incoming: day1, for: "NVDA")

        #expect(resolved == day1)
    }

    @Test("옵션 A: generatedAt이 더 최신인 응답이 오면 갱신한다")
    func newerGeneratedAtReplacesCache() async {
        let store = makeStore()
        let day1 = judgement(headline: "A", generatedAt: Date(timeIntervalSince1970: 1000))
        _ = await store.resolve(incoming: day1, for: "NVDA")

        let day6 = judgement(headline: "B", generatedAt: Date(timeIntervalSince1970: 2000))
        let resolved = await store.resolve(incoming: day6, for: "NVDA")
        let cached = await store.cached(for: "NVDA")

        #expect(resolved == day6)
        #expect(cached == day6)
    }

    @Test("옵션 B: 브리핑이 없는 날은 기존 캐시를 유지한다")
    func absentIncomingKeepsCache() async {
        let store = makeStore()
        let day1 = judgement(headline: "A", generatedAt: Date(timeIntervalSince1970: 1000))
        _ = await store.resolve(incoming: day1, for: "NVDA")

        // day2~day5: 서버가 브리핑을 아예 안 실어 보냄
        let resolved = await store.resolve(incoming: nil, for: "NVDA")

        #expect(resolved == day1)
    }

    @Test("캐시도 응답도 없으면 nil이다 (최초 실행 + 갱신일 아님)")
    func noCacheNoIncomingIsNil() async {
        let store = makeStore()

        let resolved = await store.resolve(incoming: nil, for: "NVDA")

        #expect(resolved == nil)
    }

    @Test("과거 시각의 응답(순서 역전)은 무시하고 캐시를 유지한다")
    func staleIncomingIsIgnored() async {
        let store = makeStore()
        let day6 = judgement(headline: "B", generatedAt: Date(timeIntervalSince1970: 2000))
        _ = await store.resolve(incoming: day6, for: "NVDA")

        let day1 = judgement(headline: "A", generatedAt: Date(timeIntervalSince1970: 1000))
        let resolved = await store.resolve(incoming: day1, for: "NVDA")

        #expect(resolved == day6)
    }

    @Test("generatedAt이 없는 과거 스키마는 내용 비교로 폴백한다")
    func missingGeneratedAtFallsBackToContentEquality() async {
        let store = makeStore()
        let withoutDate = judgement(headline: "A", generatedAt: nil)
        _ = await store.resolve(incoming: withoutDate, for: "NVDA")

        let sameContentAgain = judgement(headline: "A", generatedAt: nil)
        let sameResolved = await store.resolve(incoming: sameContentAgain, for: "NVDA")
        #expect(sameResolved == withoutDate)

        let differentContent = judgement(headline: "changed", generatedAt: nil)
        let changedResolved = await store.resolve(incoming: differentContent, for: "NVDA")
        #expect(changedResolved == differentContent)
    }

    @Test("티커별로 캐시가 분리된다")
    func perTickerIsolation() async {
        let store = makeStore()
        let nvda = judgement(headline: "NVDA-brief", generatedAt: Date(timeIntervalSince1970: 1000))
        let aapl = judgement(headline: "AAPL-brief", generatedAt: Date(timeIntervalSince1970: 1000))

        _ = await store.resolve(incoming: nvda, for: "NVDA")
        _ = await store.resolve(incoming: aapl, for: "AAPL")

        let cachedNVDA = await store.cached(for: "NVDA")
        let cachedAAPL = await store.cached(for: "AAPL")

        #expect(cachedNVDA == nvda)
        #expect(cachedAAPL == aapl)
    }

    @Test("대소문자와 공백이 다른 같은 티커는 캐시를 공유한다")
    func tickerKeyIsNormalized() async {
        let store = makeStore()
        let briefing = judgement(headline: "A", generatedAt: Date(timeIntervalSince1970: 1000))

        _ = await store.resolve(incoming: briefing, for: " nvda\n")
        let cached = await store.cached(for: "NVDA")

        #expect(cached == briefing)
    }

    @Test("생성 시각이 없는 응답은 생성 시각이 있는 캐시를 덮지 않는다")
    func undatedIncomingDoesNotReplaceDatedCache() async {
        let store = makeStore()
        let dated = judgement(headline: "current", generatedAt: Date(timeIntervalSince1970: 1000))
        _ = await store.resolve(incoming: dated, for: "NVDA")

        let undated = judgement(headline: "unknown", generatedAt: nil)
        let resolved = await store.resolve(incoming: undated, for: "NVDA")

        #expect(resolved == dated)
    }

    @Test("손상된 캐시는 한 번 확인한 뒤 디스크에서 제거한다")
    func corruptedCacheIsRemoved() async {
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let storageKey = "policy_finance.newsroom.aiJudgement.v1.NVDA"
        defaults.set(Data([0xFF]), forKey: storageKey)
        let store = NewsroomAIJudgementStore(defaults: defaults)

        let cached = await store.cached(for: "NVDA")

        #expect(cached == nil)
        #expect(defaults.object(forKey: storageKey) == nil)
    }
}
