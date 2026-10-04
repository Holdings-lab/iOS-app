#if DEBUG
import SwiftUI
import UIKit

/// 실제 탭/스크롤/설정 화면에 지연 응답만 주입한다. Release 빌드에는 포함되지 않는다.
@MainActor
struct DashboardUITestRootView: View {
    @StateObject private var router: AppRouter
    @State private var newsroomRepository: CachedNewsroomDigestRepository
    @State private var refreshingControls = 0
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
            Text("활성 새로고침: \(refreshingControls)")
                .font(.system(size: 9))
                .allowsHitTesting(false)
                .accessibilityIdentifier("ui.refreshControlCount")
                .padding(.bottom, 80)
        }
        .task {
            while !Task.isCancelled {
                refreshingControls = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
                    .flatMap(\.windows).reduce(0) { $0 + countRefreshingControls(in: $1) }
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    private func countRefreshingControls(in view: UIView) -> Int {
        guard !view.isHidden, view.alpha > 0 else { return 0 }
        let count = (view as? UIScrollView)?.refreshControl?.isRefreshing == true ? 1 : 0
        return count + view.subviews.reduce(0) { $0 + countRefreshingControls(in: $1) }
    }
}

private actor DashboardUITestNewsRepository: NewsroomDigestRepositoryProtocol {
    private var count = 0
    func fetchBriefing(briefingDate: String?) async throws -> NewsroomBriefing {
        count += 1
        let revision = count
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
        if briefingRequests > 1 { try await Task.sleep(for: .seconds(7)) }
    }
}
#endif
