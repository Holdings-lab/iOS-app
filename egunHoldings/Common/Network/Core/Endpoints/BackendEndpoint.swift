import Foundation

/// 2026-08 서버 리팩터(`1bed8da feat(auth): require JWT for user APIs and drop path userId`) 반영.
/// 사용자 스코프 엔드포인트는 더 이상 URL에 userId를 담지 않는다 — 서버가 `Authorization` 헤더의
/// 액세스 토큰에서 `@CurrentUserId`로 사용자를 식별하고, 미인증 요청은 401로 막는다(JwtAuthenticationFilter
/// PROTECTED_PREFIXES: `/api/me`, `/api/home`, `/api/events`, `/api/accounts`, `/api/portfolio`,
/// `/api/holdings`, `/api/goal`, `/api/goal-progress`, `/api/daily-briefing`, `/api/session`,
/// `/api/investment-profile`, `/api/newsroom`, `/api/onboarding`, `/api/watch-assets`,
/// `/api/interest-sectors`, `/api/ml`). 컨트롤러 base path도 `/api/users/{id}/...`에서
/// 리소스별 최상위 경로(`/api/me`, `/api/events`, `/api/newsroom`, `/api/onboarding`, `/api/portfolio` 등)로
/// 재편됐다 — userId 제거뿐 아니라 경로 자체가 바뀐 함수가 대부분이다.
///
/// 반면 `/api/feeds/policy*`는 이번 리팩터에 포함되지 않았다 — JWT 보호 대상도 아니고(PROTECTED_PREFIXES에
/// `/api/feeds` 없음), 여전히 `userId`를 쿼리 파라미터로 명시적으로 받는다(ContentFeedController 변경 없음).
///
nonisolated enum BackendEndpoint {
    static func emailSendCode(body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/auth/email/send-code", method: .post, body: body)
    }

    static func emailVerifyCode(body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/auth/email/verify-code", method: .post, body: body)
    }

    /// 2026-08부터 응답이 로그인과 동일한 `LoginResult`(accessToken/refreshToken 포함)로 바뀌었다.
    /// 현재 iOS는 여전히 최소 필드(`AuthAccountResponseDTO`)만 디코딩해 토큰을 못 받는다 —
    /// 회원가입 직후 자동 로그인시키려면 응답 DTO를 확장해야 한다(별도 확인 필요).
    static func register(body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/auth/signup", method: .post, body: body)
    }

    static func login(body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/auth/login", method: .post, body: body)
    }

    static func oauthLogin(body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/auth/login/oauth", method: .post, body: body)
    }

    static func logout(body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/auth/logout", method: .post, body: body)
    }

    static func accounts() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/auth/accounts", authorizationRequirement: .bearerToken)
    }

    static func deleteAccount() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me", method: .delete, authorizationRequirement: .bearerToken)
    }

    static func registerFCMToken(body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/auth/fcm-token", method: .post, body: body, authorizationRequirement: .bearerToken)
    }

    static func updateNickname(body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me/nickname", method: .patch, body: body, authorizationRequirement: .bearerToken)
    }

    static func changePassword(body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me/password", method: .patch, body: body, authorizationRequirement: .bearerToken)
    }

    static func me() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me", authorizationRequirement: .bearerToken)
    }

    static func meProfile() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me/profile", authorizationRequirement: .bearerToken)
    }

    static func watchAssets() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me/watch-assets", authorizationRequirement: .bearerToken)
    }

    static func meStudyStats() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me/study-stats", authorizationRequirement: .bearerToken)
    }

    static func meSettings() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me/settings", authorizationRequirement: .bearerToken)
    }

    /// ⚠️ 예전 타깃(`PATCH /api/me/settings`)이 이번 리팩터로 사라졌다. 서버에 남은 동급 라우트는
    /// `PATCH /api/investment-profile`뿐인데 필드가 `investmentHorizon`·`maxDrawdownTolerance` 2개뿐이라
    /// `investmentProfile`(투자 성향)을 보낼 곳이 없다 — 온보딩 5/8 값이 저장 안 될 수 있음. 확인 필요.
    static func updateInvestmentProfile(body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/investment-profile", method: .patch, body: body, authorizationRequirement: .bearerToken)
    }

    static func updateWatchAssets(body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me/watch-assets", method: .post, body: body, authorizationRequirement: .bearerToken)
    }

    static func goal() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/goal-progress", authorizationRequirement: .bearerToken)
    }

    static func updateGoal(body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/goal", method: .patch, body: body, authorizationRequirement: .bearerToken)
    }

    static func watchAssetOptions() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/watch-assets/options", authorizationRequirement: .bearerToken)
    }

    static func dailyBriefing() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/daily-briefing", authorizationRequirement: .bearerToken)
    }

    static func todayHoldings() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/holdings", authorizationRequirement: .bearerToken)
    }

    /// ⚠️ 서버 API LIST 미등재 (2026-08 재확인). 대응 엔드포인트가 없어 Mock 폴백으로 동작 중.
    static func holdingsNews() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/holdings-news", authorizationRequirement: .bearerToken)
    }

    /// body 없이 호출하면 서버의 `KIS_MOCK_*` 설정으로 모의투자 계좌를 연결한다.
    static func linkBrokerAccount() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/accounts", method: .post, authorizationRequirement: .bearerToken)
    }

    static func brokerAccounts() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/accounts", authorizationRequirement: .bearerToken)
    }

    static func syncBrokerAccount(accountId: Int64) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/accounts/\(accountId)/sync", method: .post, authorizationRequirement: .bearerToken)
    }

    static func newsroom(briefingDate: String? = nil) -> Endpoint {
        Endpoint(
            baseURL: baseURL,
            path: "/api/newsroom",
            queryItems: briefingDate.map { [URLQueryItem(name: "briefingDate", value: $0)] } ?? [],
            authorizationRequirement: .bearerToken
        )
    }

    static func newsroomDetail(ticker: String, briefingDate: String? = nil) -> Endpoint {
        Endpoint(
            baseURL: baseURL,
            path: "/api/newsroom/\(escapedPathComponent(ticker))",
            queryItems: briefingDate.map { [URLQueryItem(name: "briefingDate", value: $0)] } ?? [],
            authorizationRequirement: .bearerToken
        )
    }

    /// `/api/feeds/policy*`는 JWT 보호 대상이 아니고 userId를 여전히 쿼리로 명시해야 한다(서버 미변경).
    static func policyFeed(
        userId: Int64,
        limit: Int? = nil,
        category: String? = nil,
        dateFrom: String? = nil,
        dateTo: String? = nil
    ) -> Endpoint {
        Endpoint(
            baseURL: baseURL,
            path: "/api/feeds/policy",
            queryItems: [URLQueryItem(name: "userId", value: String(userId))]
                + policyFeedQuery(limit: limit, category: category, dateFrom: dateFrom, dateTo: dateTo),
            authorizationRequirement: .bearerToken
        )
    }

    static func policyFeedSection(
        userId: Int64,
        _ sectionPath: PolicyFeedSectionPath,
        limit: Int? = nil,
        category: String? = nil,
        dateFrom: String? = nil,
        dateTo: String? = nil
    ) -> Endpoint {
        let queryItems = sectionPath == .cards
            ? policyFeedQuery(limit: limit, category: category, dateFrom: dateFrom, dateTo: dateTo)
            : []

        return Endpoint(
            baseURL: baseURL,
            path: "/api/feeds/policy/\(sectionPath.rawValue)",
            queryItems: [URLQueryItem(name: "userId", value: String(userId))] + queryItems,
            authorizationRequirement: .bearerToken
        )
    }

    static func events(dateSegment: String = "all", category: String = "all") -> Endpoint {
        Endpoint(
            baseURL: baseURL,
            path: "/api/events",
            queryItems: eventQuery(dateSegment: dateSegment, category: category),
            authorizationRequirement: .bearerToken
        )
    }

    static func updateEventAlert(eventId: Int64, body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/events/\(eventId)/alerts", method: .post, body: body, authorizationRequirement: .bearerToken)
    }

    static func eventSection(_ sectionPath: EventSectionPath, dateSegment: String = "all", category: String = "all") -> Endpoint {
        let queryItems = sectionPath == .items
            ? eventQuery(dateSegment: dateSegment, category: category)
            : []

        return Endpoint(baseURL: baseURL, path: "/api/events/\(sectionPath.rawValue)", queryItems: queryItems, authorizationRequirement: .bearerToken)
    }

    /// ⚠️ 서버 API LIST 미등재. `/api/signals/*` 네임스페이스 자체가 서버에 없다.
    static func signalDetail(id: String) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/signals/\(escapedPathComponent(id))", authorizationRequirement: .bearerToken)
    }

    static func signalThemes() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/signals/themes", authorizationRequirement: .bearerToken)
    }

    static func signalCards(theme: String) -> Endpoint {
        Endpoint(
            baseURL: baseURL,
            path: "/api/signals/cards",
            queryItems: [URLQueryItem(name: "theme", value: theme)],
            authorizationRequirement: .bearerToken
        )
    }

    static func heatmap(marketScope: String = "all", country: String = "all") -> Endpoint {
        Endpoint(
            baseURL: baseURL,
            path: "/api/insights/heatmap",
            queryItems: [
                URLQueryItem(name: "marketScope", value: marketScope),
                URLQueryItem(name: "country", value: country),
            ],
            authorizationRequirement: .bearerToken
        )
    }

    static func portfolio() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/portfolio", authorizationRequirement: .bearerToken)
    }

    static func insightSection(_ sectionPath: InsightSectionPath) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/insights/\(sectionPath.rawValue)", authorizationRequirement: .bearerToken)
    }

    static func health() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/health")
    }

    static func internalWebhookEvent(body: Data, secret: String? = nil) -> Endpoint {
        var headers: [String: String] = [:]
        if let secret, !secret.isEmpty {
            headers["X-Webhook-Secret"] = secret
        }

        return Endpoint(baseURL: baseURL, path: "/api/internal/webhooks/events", method: .post, headers: headers, body: body)
    }

    private static let baseURL = NetworkConfiguration.backendBaseURL

    private static func eventQuery(dateSegment: String, category: String) -> [URLQueryItem] {
        [
            URLQueryItem(name: "dateSegment", value: dateSegment),
            URLQueryItem(name: "category", value: category),
        ]
    }

    private static func policyFeedQuery(
        limit: Int?,
        category: String?,
        dateFrom: String?,
        dateTo: String?
    ) -> [URLQueryItem] {
        [
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

    private static func escapedPathComponent(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? value
    }
}

nonisolated enum PolicyFeedSectionPath: String {
    case cards
    case filters
    case meta
    case model
    case source
    case summary
}

nonisolated enum EventSectionPath: String {
    case categories
    case dateSegments = "date-segments"
    case items
}

nonisolated enum InsightSectionPath: String {
    case columns = "heatmap/columns"
    case legend = "heatmap/legend"
    case rows = "heatmap/rows"
    case viewTabs = "tabs"
}
