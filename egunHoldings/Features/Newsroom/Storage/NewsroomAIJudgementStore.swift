import Foundation

/// AI 브리핑 로컬 캐시.
///
/// 예측 배치는 뉴스 크롤링과 같이 매일 도는데, 크롤링 결과가 비거나 배치가 실패하는 날은
/// 그날 상세 응답에 브리핑이 안 실릴 수 있다. 서버가 그런 날 값을 아예 생략하든, 어제 값을
/// 그대로 다시 보내든 — 클라이언트는 같은 규칙 하나로 처리한다:
/// "더 새로운 게 오면 갈아끼우고, 아니면 갖고 있던 걸 유지".
///
/// 세션 메모리가 아니라 디스크에 두는 이유: 브리핑이 안 실려 오는 날 앱을 재실행하면
/// 메모리 캐시로는 보여줄 값이 없어져 섹션이 통째로 사라진다.
protocol NewsroomAIJudgementStoring: Sendable {
    nonisolated func cached(for ticker: String) -> NewsroomAIJudgement?
    /// 응답과 캐시를 비교해 화면에 쓸 브리핑을 정하고, 응답이 더 새로우면 저장한다.
    nonisolated func resolve(incoming: NewsroomAIJudgement?, for ticker: String) -> NewsroomAIJudgement?
}

nonisolated final class NewsroomAIJudgementStore: NewsroomAIJudgementStoring, @unchecked Sendable {
    private let defaults: UserDefaults
    private let keyPrefix = "policy_finance.newsroom.aiJudgement.v1."
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    nonisolated func cached(for ticker: String) -> NewsroomAIJudgement? {
        guard let data = defaults.data(forKey: key(for: ticker)) else { return nil }
        return try? decoder.decode(NewsroomAIJudgement.self, from: data)
    }

    nonisolated func resolve(incoming: NewsroomAIJudgement?, for ticker: String) -> NewsroomAIJudgement? {
        let cached = cached(for: ticker)

        // 이번 응답에 브리핑이 없다 → 갱신일이 아닌 날. 갖고 있던 걸 그대로 쓴다.
        guard let incoming else { return cached }

        guard let cached else {
            save(incoming, for: ticker)
            return incoming
        }

        if let incomingAt = incoming.generatedAt, let cachedAt = cached.generatedAt {
            // 같은 값을 매일 다시 받는 경우가 여기 걸린다 — 저장도 갱신도 하지 않는다.
            // 순서가 뒤집힌 응답(캐시보다 과거)도 같은 이유로 무시된다.
            guard incomingAt > cachedAt else { return cached }
            save(incoming, for: ticker)
            return incoming
        }

        // 한쪽이라도 생성일이 없으면 시간순을 못 따지므로 내용 비교로 갈음한다.
        // 서버가 아직 generatedAt을 안 내려주는 동안의 폴백이다.
        guard incoming != cached else { return cached }
        save(incoming, for: ticker)
        return incoming
    }

    private nonisolated func save(_ judgement: NewsroomAIJudgement, for ticker: String) {
        guard let data = try? encoder.encode(judgement) else { return }
        defaults.set(data, forKey: key(for: ticker))
    }

    private nonisolated func key(for ticker: String) -> String {
        keyPrefix + ticker.uppercased()
    }
}
