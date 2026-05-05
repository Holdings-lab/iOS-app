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
        Endpoint(baseURL: baseURL, path: "/api/me", queryItems: userQuery(userId), authorizationRequirement: .bearerToken)
    }

    static func notificationSettings(userId: Int64) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me/settings/notifications", queryItems: userQuery(userId), authorizationRequirement: .bearerToken)
    }

    static func updateNotificationSettings(userId: Int64, body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me/settings/notifications", queryItems: userQuery(userId), method: .patch, body: body, authorizationRequirement: .bearerToken)
    }

    static func updateWatchAssets(userId: Int64, body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me/watch-assets", queryItems: userQuery(userId), method: .post, body: body, authorizationRequirement: .bearerToken)
    }

    static func watchAssetOptions() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me/watch-assets/options", authorizationRequirement: .bearerToken)
    }

    static func meProfile() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me/profile", authorizationRequirement: .bearerToken)
    }

    static func meSettingsMenu() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me/settings-menu", authorizationRequirement: .bearerToken)
    }

    static func meStudyStats() -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/me/study-stats", authorizationRequirement: .bearerToken)
    }

    static func home(userId: Int64) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/home", queryItems: userQuery(userId), authorizationRequirement: .bearerToken)
    }

    static func todayDashboard(userId: Int64) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/home", queryItems: userQuery(userId), authorizationRequirement: .bearerToken)
    }

    static func homeBriefing(userId: Int64) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/home/briefing", queryItems: userQuery(userId), authorizationRequirement: .bearerToken)
    }

    static func homeSection(_ sectionPath: HomeSectionPath) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/home/\(sectionPath.rawValue)", authorizationRequirement: .bearerToken)
    }

    static func policyFeed(body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/content/policy-feed", method: .post, body: body, authorizationRequirement: .bearerToken)
    }

    static func policyFeedSection(_ sectionPath: PolicyFeedSectionPath, body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/content/policy-feed/\(sectionPath.rawValue)", method: .post, body: body, authorizationRequirement: .bearerToken)
    }

    static func events(userId: Int64, dateSegment: String = "today", category: String = "all") -> Endpoint {
        Endpoint(
            baseURL: baseURL,
            path: "/api/events",
            queryItems: eventQuery(userId: userId, dateSegment: dateSegment, category: category),
            authorizationRequirement: .bearerToken
        )
    }

    static func refreshEvents(userId: Int64, dateSegment: String = "today", category: String = "all") -> Endpoint {
        Endpoint(
            baseURL: baseURL,
            path: "/api/events/refresh",
            queryItems: eventQuery(userId: userId, dateSegment: dateSegment, category: category),
            method: .post,
            body: NetworkJSONCoding.encodeEmptyJSONObject(),
            authorizationRequirement: .bearerToken
        )
    }

    static func updateEventAlert(eventId: Int64, userId: Int64, body: Data) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/events/\(eventId)/alerts", queryItems: userQuery(userId), method: .post, body: body, authorizationRequirement: .bearerToken)
    }

    static func eventSection(_ sectionPath: EventSectionPath) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/events/\(sectionPath.rawValue)", authorizationRequirement: .bearerToken)
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
        Endpoint(baseURL: baseURL, path: "/api/portfolio", queryItems: userQuery(userId), authorizationRequirement: .bearerToken)
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

    private static func eventQuery(userId: Int64, dateSegment: String, category: String) -> [URLQueryItem] {
        [
            URLQueryItem(name: "userId", value: String(userId)),
            URLQueryItem(name: "dateSegment", value: dateSegment),
            URLQueryItem(name: "category", value: category),
        ]
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
    case featuredCard = "featured-card"
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
    case countryFilters = "country-filters"
    case legend
    case rows
}
