#if DEBUG
import SwiftUI

/// 실제 탭/스크롤/설정 화면에 지연 응답만 주입한다. Release 빌드에는 포함되지 않는다.
@MainActor
struct DashboardUITestRootView: View {
    @StateObject private var router: AppRouter
    @State private var newsroomRepository: CachedNewsroomDigestRepository
    @State private var verifiedSwitches = 0
    @State private var isSwitching = false
    private let apiClient = DashboardUITestAPIClient()

    init() {
        let defaults = UserDefaults(suiteName: "dashboard-ui-test")!
        defaults.removePersistentDomain(forName: "dashboard-ui-test")
        let store = AuthSessionStore(defaults: defaults)
        store.save(AppUserSession(userId: 999, token: "ui-test", expiresAt: Date().addingTimeInterval(3600),
                                  userName: "UI 테스트", email: "ui@test.example", onboardingCompleted: true,
                                  onboardingResult: nil, brokerBalanceSnapshot: AppMockData.brokerBalanceSnapshot))
        _router = StateObject(wrappedValue: AppRouter(store: store, accountStore: AuthAccountStore(defaults: defaults)))
        _newsroomRepository = State(initialValue: CachedNewsroomDigestRepository(repository: DashboardUITestNewsRepository()))
    }

    var body: some View {
        RootTabView(
            userId: router.session?.userId,
            onboardingResult: router.session?.onboardingResult,
            userAssetProfile: router.userAssetProfile,
            portfolioSnapshot: router.portfolioSnapshot,
            brokerBalanceSnapshot: router.session?.brokerBalanceSnapshot,
            onBrokerBalanceUpdated: router.updateBrokerBalance,
            onGoalSaved: router.updateGoal,
            newsroomRepository: newsroomRepository,
            todayRepository: LiveTodayRepository(apiClient: apiClient, newsroomRepository: newsroomRepository,
                                                  newsTimeout: .milliseconds(500)),
            settingsRepository: LiveSettingsRepository(apiClient: apiClient)
        )
        .overlay(alignment: .bottomLeading) {
            Text("로딩 중 탭 왕복 확인: \(verifiedSwitches)")
                .accessibilityIdentifier("ui.verifiedTabSwitches")
            .font(.system(size: 9))
            .allowsHitTesting(false)
            .padding(.bottom, 80)
        }
        .onReceive(NotificationCenter.default.publisher(for: .dashboardUITestRefreshStarted)) { notification in
            guard ProcessInfo.processInfo.arguments.contains("-ui-testing-switch-during-refresh"),
                  !isSwitching, let original = notification.object as? RootTab else { return }
            isSwitching = true
            Task { @MainActor in
                NotificationCenter.default.post(name: .dashboardUITestTabRequested,
                                                object: original == .today ? RootTab.newsroom : .today)
                try? await Task.sleep(for: .milliseconds(200))
                NotificationCenter.default.post(name: .dashboardUITestTabRequested, object: original)
                verifiedSwitches += 1
                isSwitching = false
            }
        }
    }

}

extension Notification.Name {
    static let dashboardUITestTabRequested = Notification.Name("dashboardUITestTabRequested")
    static let dashboardUITestRefreshStarted = Notification.Name("dashboardUITestRefreshStarted")
}

private actor DashboardUITestNewsRepository: NewsroomDigestRepositoryProtocol {
    private var count = 0
    func fetchBriefing(briefingDate: String?) async throws -> NewsroomBriefing {
        count += 1
        let revision = count
        if revision >= 3 {
            await MainActor.run {
                NotificationCenter.default.post(name: .dashboardUITestRefreshStarted, object: RootTab.newsroom)
            }
        }
        try await Task.sleep(for: .milliseconds(revision == 1 ? 800 : 7_000))
        return NewsroomBriefing(title: "뉴스룸", asOfAt: Date(), subtitle: "UI 테스트", holdings: [
            NewsroomHoldingBriefing(ticker: "NVDA", name: "NVIDIA", logoURL: nil, weightPercent: 100,
                                    briefingType: .hero, dailyChangePercent: 1,
                                    headline: "UI 서버 뉴스 \(revision)", summary: "지연 응답 확인", detailPath: nil)
        ], footerMessage: nil, emptyState: nil, errorState: nil)
    }
    func fetchDetail(ticker: String, briefingDate: String?) async throws -> NewsroomTickerDetail {
        throw URLError(.unsupportedURL)
    }
}

private nonisolated struct DashboardUITestAPIClient: APIClient {
    private let delays = DashboardUITestRequestDelays()
    func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        try await delays.pause(for: endpoint.path)
        let result: String
        switch endpoint.path {
        case "/api/daily-briefing": result = #"{"isAccountLinked":true,"drawdownPct":-2}"#
        case "/api/holdings": result = #"{"isAccountLinked":true,"holdings":[]}"#
        case "/api/me/settings":
            result = #"{"user":{"nickname":"UI 테스트","email":"ui@test.example","avatarText":"U"},"notifications":{"policyChangeAlert":false,"briefingTime":"09:00"},"investment":{"goal":null,"connectedAccounts":{"count":1,"expiredCount":0},"interests":{"count":0}}}"#
        default: throw URLError(.unsupportedURL)
        }
        return try NetworkJSONCoding.makeDecoder().decode(type, from: Data(
            #"{"isSuccess":true,"code":"SUCCESS-200","message":"OK","result":\#(result)}"#.utf8
        ))
    }
}

private actor DashboardUITestRequestDelays {
    private var briefingRequests = 0
    func pause(for path: String) async throws {
        guard path == "/api/daily-briefing" else { return }
        briefingRequests += 1
        if briefingRequests > 1 {
            await MainActor.run {
                NotificationCenter.default.post(name: .dashboardUITestRefreshStarted, object: RootTab.today)
            }
            try await Task.sleep(for: .seconds(7))
        }
    }
}
#endif
