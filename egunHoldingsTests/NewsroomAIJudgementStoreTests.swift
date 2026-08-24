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
    func firstFetchAdoptsIncoming() {
        let store = makeStore()
        let day1 = judgement(headline: "A", generatedAt: Date(timeIntervalSince1970: 1000))

        let resolved = store.resolve(incoming: day1, for: "NVDA")

        #expect(resolved == day1)
        #expect(store.cached(for: "NVDA") == day1)
    }

    @Test("옵션 A: 매일 같은 값이 다시 와도 갱신하지 않는다")
    func dailyResendOfSameValueIsNoOp() {
        let store = makeStore()
        let day1 = judgement(headline: "A", generatedAt: Date(timeIntervalSince1970: 1000))
        _ = store.resolve(incoming: day1, for: "NVDA")

        // 다음날에도 서버가 같은 generatedAt으로 같은 값을 다시 보냄
        let resolved = store.resolve(incoming: day1, for: "NVDA")

        #expect(resolved == day1)
    }

    @Test("옵션 A: generatedAt이 더 최신인 응답이 오면 갱신한다")
    func newerGeneratedAtReplacesCache() {
        let store = makeStore()
        let day1 = judgement(headline: "A", generatedAt: Date(timeIntervalSince1970: 1000))
        _ = store.resolve(incoming: day1, for: "NVDA")

        let day6 = judgement(headline: "B", generatedAt: Date(timeIntervalSince1970: 2000))
        let resolved = store.resolve(incoming: day6, for: "NVDA")

        #expect(resolved == day6)
        #expect(store.cached(for: "NVDA") == day6)
    }

    @Test("옵션 B: 브리핑이 없는 날은 기존 캐시를 유지한다")
    func absentIncomingKeepsCache() {
        let store = makeStore()
        let day1 = judgement(headline: "A", generatedAt: Date(timeIntervalSince1970: 1000))
        _ = store.resolve(incoming: day1, for: "NVDA")

        // day2~day5: 서버가 브리핑을 아예 안 실어 보냄
        let resolved = store.resolve(incoming: nil, for: "NVDA")

        #expect(resolved == day1)
    }

    @Test("캐시도 응답도 없으면 nil이다 (최초 실행 + 갱신일 아님)")
    func noCacheNoIncomingIsNil() {
        let store = makeStore()

        let resolved = store.resolve(incoming: nil, for: "NVDA")

        #expect(resolved == nil)
    }

    @Test("과거 시각의 응답(순서 역전)은 무시하고 캐시를 유지한다")
    func staleIncomingIsIgnored() {
        let store = makeStore()
        let day6 = judgement(headline: "B", generatedAt: Date(timeIntervalSince1970: 2000))
        _ = store.resolve(incoming: day6, for: "NVDA")

        let day1 = judgement(headline: "A", generatedAt: Date(timeIntervalSince1970: 1000))
        let resolved = store.resolve(incoming: day1, for: "NVDA")

        #expect(resolved == day6)
    }

    @Test("generatedAt이 없는 과거 스키마는 내용 비교로 폴백한다")
    func missingGeneratedAtFallsBackToContentEquality() {
        let store = makeStore()
        let withoutDate = judgement(headline: "A", generatedAt: nil)
        _ = store.resolve(incoming: withoutDate, for: "NVDA")

        let sameContentAgain = judgement(headline: "A", generatedAt: nil)
        #expect(store.resolve(incoming: sameContentAgain, for: "NVDA") == withoutDate)

        let differentContent = judgement(headline: "changed", generatedAt: nil)
        #expect(store.resolve(incoming: differentContent, for: "NVDA") == differentContent)
    }

    @Test("티커별로 캐시가 분리된다")
    func perTickerIsolation() {
        let store = makeStore()
        let nvda = judgement(headline: "NVDA-brief", generatedAt: Date(timeIntervalSince1970: 1000))
        let aapl = judgement(headline: "AAPL-brief", generatedAt: Date(timeIntervalSince1970: 1000))

        _ = store.resolve(incoming: nvda, for: "NVDA")
        _ = store.resolve(incoming: aapl, for: "AAPL")

        #expect(store.cached(for: "NVDA") == nvda)
        #expect(store.cached(for: "AAPL") == aapl)
    }
}
