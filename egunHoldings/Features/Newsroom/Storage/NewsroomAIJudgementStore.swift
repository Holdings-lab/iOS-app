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
    func cached(for ticker: String) async -> NewsroomAIJudgement?
    /// 응답과 캐시를 비교해 화면에 쓸 브리핑을 정하고, 응답이 더 새로우면 저장한다.
    func resolve(incoming: NewsroomAIJudgement?, for ticker: String) async -> NewsroomAIJudgement?
}

/// Foundation의 `UserDefaults`는 스레드 안전하지만 Swift 동시성 표기는 Sendable이 아니다.
/// 이 actor만 보관·접근하므로 경계를 한 번만 명시한다.
private nonisolated struct NewsroomUserDefaultsStorage: @unchecked Sendable {
    let value: UserDefaults
}

actor NewsroomAIJudgementStore: NewsroomAIJudgementStoring {
    static let shared = NewsroomAIJudgementStore()

    private let defaultsStorage: NewsroomUserDefaultsStorage
    private let keyPrefix = "policy_finance.newsroom.aiJudgement.v1."
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var memoryCache: [String: NewsroomAIJudgement] = [:]
    private var loadedKeys: Set<String> = []

    init(defaults: UserDefaults = .standard) {
        defaultsStorage = NewsroomUserDefaultsStorage(value: defaults)
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func cached(for ticker: String) async -> NewsroomAIJudgement? {
        cachedValue(for: ticker)
    }

    func resolve(incoming: NewsroomAIJudgement?, for ticker: String) async -> NewsroomAIJudgement? {
        let cached = cachedValue(for: ticker)

        // 이번 응답에 브리핑이 없다 → 갱신일이 아닌 날. 갖고 있던 걸 그대로 쓴다.
        guard let incoming else { return cached }

        guard let cached else {
            save(incoming, for: ticker)
            return incoming
        }

        switch (incoming.generatedAt, cached.generatedAt) {
        case let (incomingAt?, cachedAt?):
            // 같은 값을 매일 다시 받는 경우가 여기 걸린다 — 저장도 갱신도 하지 않는다.
            // 순서가 뒤집힌 응답(캐시보다 과거)도 같은 이유로 무시된다.
            guard incomingAt > cachedAt else { return cached }
            save(incoming, for: ticker)
            return incoming
        case (.some, .none):
            // 생성 시각을 새로 제공하기 시작한 응답은 기존 무시각 캐시보다 신뢰한다.
            save(incoming, for: ticker)
            return incoming
        case (.none, .some):
            // 일시적인 구버전 응답이 생성 시각이 있는 캐시를 덮지 않게 한다.
            return cached
        case (.none, .none):
            break
        }

        // 양쪽 모두 생성일이 없는 구버전 데이터끼리는 내용 비교로 갈음한다.
        guard incoming != cached else { return cached }
        save(incoming, for: ticker)
        return incoming
    }

    private func cachedValue(for ticker: String) -> NewsroomAIJudgement? {
        let storageKey = key(for: ticker)
        guard !loadedKeys.contains(storageKey) else { return memoryCache[storageKey] }

        loadedKeys.insert(storageKey)
        guard let data = defaultsStorage.value.data(forKey: storageKey) else { return nil }

        do {
            let judgement = try decoder.decode(NewsroomAIJudgement.self, from: data)
            memoryCache[storageKey] = judgement
            return judgement
        } catch {
            // 손상된 데이터를 매번 다시 디코딩하지 않도록 즉시 제거한다.
            defaultsStorage.value.removeObject(forKey: storageKey)
            return nil
        }
    }

    private func save(_ judgement: NewsroomAIJudgement, for ticker: String) {
        let storageKey = key(for: ticker)
        loadedKeys.insert(storageKey)
        memoryCache[storageKey] = judgement

        guard let data = try? encoder.encode(judgement) else { return }
        defaultsStorage.value.set(data, forKey: storageKey)
    }

    private func key(for ticker: String) -> String {
        let normalizedTicker = ticker
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        return keyPrefix + normalizedTicker
    }
}
