import Foundation

nonisolated enum BackendEndpoint {
    static func emailSendCode(body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/auth/email/send-code", method: .post, body: body)
    }

    static func emailVerifyCode(body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/auth/email/verify-code", method: .post, body: body)
    }

    static func register(body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/auth/register", method: .post, body: body)
    }

    static func login(body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/auth/login", method: .post, body: body)
    }

    static func oauthLogin(body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/auth/oauth-login", method: .post, body: body)
    }

    static func accounts() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/auth/accounts", authorizationRequirement: .bearerToken)
    }

    static func deleteAccount(userId: Int64) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/auth/delete/\(userId)", method: .delete, authorizationRequirement: .bearerToken)
    }

    static func registerFCMToken(body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/auth/register-fcm-token", method: .post, body: body, authorizationRequirement: .bearerToken)
    }

    static func updateNickname(userId: Int64, body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/auth/users/\(userId)/nickname", method: .patch, body: body, authorizationRequirement: .bearerToken)
    }

    static func changePassword(userId: Int64, body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/auth/users/\(userId)/change-password", method: .post, body: body, authorizationRequirement: .bearerToken)
    }

    static func me(userId: Int64) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me/\(userId)", authorizationRequirement: .bearerToken)
    }

    static func meProfile(userId: Int64) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me/\(userId)/profile", authorizationRequirement: .bearerToken)
    }

    static func investmentProfile(userId: Int64) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me/\(userId)/investment-profile", authorizationRequirement: .bearerToken)
    }

    static func updateInvestmentProfile(userId: Int64, body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me/\(userId)/investment-profile", method: .patch, body: body, authorizationRequirement: .bearerToken)
    }

    static func watchAssets(userId: Int64) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me/\(userId)/watch-assets", authorizationRequirement: .bearerToken)
    }

    static func meStudyStats(userId: Int64) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me/\(userId)/study-stats", authorizationRequirement: .bearerToken)
    }

    static func meSettings(userId: Int64) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me/\(userId)/settings", authorizationRequirement: .bearerToken)
    }

    static func updateMeSettings(userId: Int64, body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me/\(userId)/settings", method: .patch, body: body, authorizationRequirement: .bearerToken)
    }

    static func updateWatchAssets(userId: Int64, body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me/\(userId)/watch-assets", method: .post, body: body, authorizationRequirement: .bearerToken)
    }

    static func watchAssetOptions() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me/watch-assets/options", authorizationRequirement: .bearerToken)
    }

    static func home(userId: Int64) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/home/\(userId)", authorizationRequirement: .bearerToken)
    }

    static func todayDashboard(userId: Int64) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/home/\(userId)", authorizationRequirement: .bearerToken)
    }

    static func homeBriefing(userId: Int64) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/home/\(userId)/briefing", authorizationRequirement: .bearerToken)
    }

    static func homeSection(userId: Int64, _ sectionPath: HomeSectionPath) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/home/\(userId)/\(sectionPath.rawValue)", authorizationRequirement: .bearerToken)
    }

    static func policyFeed(
        userId: Int64,
        limit: Int? = nil,
        category: String? = nil,
        dateFrom: String? = nil,
        dateTo: String? = nil
    ) -> Endpoint {
        Endpoint(
            baseURL: baseURL,
            path: "/api/content/\(userId)/policy-feed",
            queryItems: policyFeedQuery(limit: limit, category: category, dateFrom: dateFrom, dateTo: dateTo),
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
            path: "/api/content/\(userId)/policy-feed/\(sectionPath.rawValue)",
            queryItems: queryItems,
            authorizationRequirement: .bearerToken
        )
    }

    static func events(userId: Int64, dateSegment: String = "all", category: String = "all") -> Endpoint {
        Endpoint(
            baseURL: baseURL,
            path: "/api/events/\(userId)",
            queryItems: eventQuery(dateSegment: dateSegment, category: category),
            authorizationRequirement: .bearerToken
        )
    }

    static func updateEventAlert(eventId: Int64, userId: Int64, body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/events/\(userId)/\(eventId)/alerts", method: .post, body: body, authorizationRequirement: .bearerToken)
    }

    static func eventSection(userId: Int64, _ sectionPath: EventSectionPath, dateSegment: String = "all", category: String = "all") -> Endpoint {
        let queryItems = sectionPath == .items
            ? eventQuery(dateSegment: dateSegment, category: category)
            : []

        return Endpoint(baseURL: baseURL, path: "/api/events/\(userId)/\(sectionPath.rawValue)", queryItems: queryItems, authorizationRequirement: .bearerToken)
    }

    static func signalDetail(id: String) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/signals/\(escapedPathComponent(id))", authorizationRequirement: .bearerToken)
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

    static func portfolio(userId: Int64) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/portfolio/\(userId)", authorizationRequirement: .bearerToken)
    }

    static func portfolioRebalancing(userId: Int64) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/portfolio/\(userId)/rebalancing", authorizationRequirement: .bearerToken)
    }

    static func portfolioRebalancingPreview(userId: Int64, body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/portfolio/\(userId)/rebalancing/preview", method: .post, body: body, authorizationRequirement: .bearerToken)
    }

    static func insightSection(_ sectionPath: InsightSectionPath) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/insights/\(sectionPath.rawValue)", authorizationRequirement: .bearerToken)
    }

    static func trainRegression() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/ai/train-regression", method: .post, body: NetworkJSONCoding.encodeEmptyJSONObject(), authorizationRequirement: .bearerToken)
    }

    static func triggerAI(userId: Int64, body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/ai/trigger", queryItems: userQuery(userId), method: .post, body: body, authorizationRequirement: .bearerToken)
    }

    static func health() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/health")
    }

    static func internalWebhookEvent(body: Data, secret: String? = nil) -> Endpoint {
        var headers: [String: String] = [:]
        if let secret, !secret.isEmpty {
            headers["X-Webhook-Secret"] = secret
        }

        return Endpoint(baseURL: baseURL, path: "/api/internal/webhook/event", method: .post, headers: headers, body: body)
    }

    static func adminAccounts(page: Int = 0, size: Int = 100) -> Endpoint {
        Endpoint(
            baseURL: baseURL,
            path: "/admin/accounts",
            queryItems: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "size", value: String(size)),
            ],
            authorizationRequirement: .bearerToken
        )
    }

    static func adminAddAccount(body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/admin/accounts/add", method: .post, body: body, authorizationRequirement: .bearerToken)
    }

    static func adminChangePassword(body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/admin/accounts/change-password", method: .post, body: body, authorizationRequirement: .bearerToken)
    }

    static func adminDeleteAccount(userId: Int64) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/admin/accounts/\(userId)", method: .delete, authorizationRequirement: .bearerToken)
    }

    static func adminUpdateFCMToken(userId: Int64, fcmToken: String) -> Endpoint {
        Endpoint(
            baseURL: baseURL,
            path: "/admin/accounts/\(userId)/fcm-token",
            queryItems: [URLQueryItem(name: "fcmToken", value: fcmToken)],
            method: .patch,
            authorizationRequirement: .bearerToken
        )
    }

    static func adminSendNotification(body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/admin/notifications/send", method: .post, body: body, authorizationRequirement: .bearerToken)
    }

    private static let baseURL = NetworkConfiguration.backendBaseURL

    private static func userQuery(_ userId: Int64) -> [URLQueryItem] {
        [URLQueryItem(name: "userId", value: String(userId))]
    }

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

nonisolated enum HomeSectionPath: String {
    case checkpointTab = "checkpoint-tab"
    case detailTabs = "detail-tabs"
    case disclaimer
    case featuredCard = "featured-card"
    case header
    case portfolioCard = "portfolio-card"
    case quickInterpretation = "quick-interpretation"
    case secondarySignals = "secondary-signals"
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
    case columns
    case legend
    case rows
    case viewTabs = "view-tabs"
}
