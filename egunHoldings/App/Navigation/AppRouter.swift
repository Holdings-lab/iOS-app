import Combine
import Foundation

@MainActor
final class AppRouter: ObservableObject {
    @Published private(set) var route: AppRoute = .loading
    @Published private(set) var userAssetProfile: UserAssetProfile = AppMockData.userAssetProfile
    @Published private(set) var portfolioSnapshot: PortfolioSnapshot = AppMockData.portfolioSnapshot
    @Published private(set) var userName: String = "투자자"

    private let store: AuthSessionStoring
    private let accountStore: AuthAccountStoring
    private let brokerBalanceRepository: BrokerBalanceRepositoryProtocol
    private(set) var session: AppUserSession?
    private var lastAuthenticatedEmail: String?

    init(
        store: AuthSessionStoring? = nil,
        accountStore: AuthAccountStoring? = nil,
        brokerBalanceRepository: BrokerBalanceRepositoryProtocol? = nil
    ) {
        self.store = store ?? AuthSessionStore()
        self.accountStore = accountStore ?? AuthAccountStore()
        self.brokerBalanceRepository = brokerBalanceRepository ?? KisSandboxBalanceRepository()
        bootstrap()
    }

    func bootstrap() {
        guard let savedSession = store.load() else {
            clearSessionAndMoveToAuth()
            return
        }

        guard savedSession.isTokenValid else {
            clearSessionAndMoveToAuth()
            return
        }

        session = savedSession
        lastAuthenticatedEmail = savedSession.email
        applySessionDerivedData(from: savedSession)

        route = savedSession.onboardingCompleted ? .main : .onboarding

        if shouldRefreshBrokerBalance(for: savedSession) {
            Task {
                await refreshBrokerBalance(forSessionToken: savedSession.token)
            }
        }
    }

    func handleLoginSuccess(session newSession: AppUserSession) {
        let isNewUser = newSession.onboardingCompleted == false
        saveSession(newSession)
        route = isNewUser ? .onboarding : .main

        if shouldRefreshBrokerBalance(for: newSession) {
            Task {
                await refreshBrokerBalance(forSessionToken: newSession.token)
            }
        }
    }

    func completeOnboarding(with result: OnboardingResult) {
        guard var currentSession = session ?? makeFallbackSession(for: result) else {
            userAssetProfile = AuthMockData.makeAssetProfile(from: result)
            portfolioSnapshot = AppMockData.portfolioSnapshot
            route = .main
            return
        }

        currentSession.onboardingCompleted = true
        currentSession.onboardingResult = result
        currentSession.brokerBalanceSnapshot = nil

        saveSession(currentSession)
        route = .main

        if shouldRefreshBrokerBalance(for: currentSession) {
            Task {
                await refreshBrokerBalance(forSessionToken: currentSession.token)
            }
        }
    }

    func logout() {
        clearSessionAndMoveToAuth()
    }

    func registeredAccount(for email: String) -> RegisteredAuthAccount? {
        accountStore.loadAll().first { $0.normalizedEmail == normalizedEmail(from: email) }
    }

    private func applySessionDerivedData(from session: AppUserSession) {
        userName = session.userName

        if let brokerBalanceSnapshot = session.brokerBalanceSnapshot {
            userAssetProfile = brokerBalanceSnapshot.toUserAssetProfile()
            portfolioSnapshot = brokerBalanceSnapshot.toPortfolioSnapshot()
        } else {
            userAssetProfile = AuthMockData.makeAssetProfile(from: session.onboardingResult)
            portfolioSnapshot = AppMockData.portfolioSnapshot
        }
    }

    private func saveSession(_ session: AppUserSession) {
        self.session = session
        lastAuthenticatedEmail = session.email
        applySessionDerivedData(from: session)
        store.save(session)
        syncRegisteredAccount(with: session)
    }

    private func clearSessionAndMoveToAuth() {
        session = nil
        lastAuthenticatedEmail = nil
        userAssetProfile = AppMockData.userAssetProfile
        portfolioSnapshot = AppMockData.portfolioSnapshot
        userName = "투자자"
        store.clear()
        route = .auth
    }

    private func normalizedEmail(from email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func syncRegisteredAccount(with session: AppUserSession) {
        var accounts = accountStore.loadAll()
        guard let index = accounts.firstIndex(where: { $0.normalizedEmail == normalizedEmail(from: session.email) }) else {
            return
        }

        accounts[index].userId = session.userId
        accounts[index].onboardingCompleted = session.onboardingCompleted
        accounts[index].onboardingResult = session.onboardingResult
        accounts[index].brokerBalanceSnapshot = session.brokerBalanceSnapshot
        accountStore.saveAll(accounts)
    }

    private func shouldRefreshBrokerBalance(for session: AppUserSession) -> Bool {
        session.onboardingResult?.connectedInstitutionIDs.contains(AccountInstitution.koreaInvestmentID) == true
            || session.brokerBalanceSnapshot != nil
    }

    private func makeFallbackSession(for result: OnboardingResult) -> AppUserSession? {
        guard let lastAuthenticatedEmail,
              let account = registeredAccount(for: lastAuthenticatedEmail)
        else {
            return nil
        }

        return AppUserSession(
            userId: account.userId,
            token: UUID().uuidString,
            refreshToken: nil,
            expiresAt: Date().addingTimeInterval(60 * 60 * 24 * 14),
            userName: account.userName,
            email: account.email,
            onboardingCompleted: false,
            onboardingResult: result,
            brokerBalanceSnapshot: nil
        )
    }

    private func refreshBrokerBalance(forSessionToken sessionToken: String) async {
        do {
            Self.debugLog("로그인/부트스트랩 잔고조회 시작: sessionToken=\(sessionToken)")
            let snapshot = try await brokerBalanceRepository.fetchKisSandboxBalance()

            guard var currentSession = session, currentSession.token == sessionToken else {
                Self.debugLog("잔고조회 응답 무시: 세션 토큰이 이미 변경되었습니다.")
                return
            }

            currentSession.brokerBalanceSnapshot = snapshot
            saveSession(currentSession)
            Self.debugLog("로그인/부트스트랩 잔고조회 저장 완료: total=\(snapshot.totalEvaluationAmount), cash=\(snapshot.cashAmount)")
        } catch {
            Self.debugLog("로그인/부트스트랩 잔고조회 실패: \(String(describing: error))")
        }
    }

    private static func debugLog(_ message: String) {
#if DEBUG
        print("[BrokerBalance] \(message)")
#endif
    }
}
