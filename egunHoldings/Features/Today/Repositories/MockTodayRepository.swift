import Foundation

nonisolated struct MockTodayRepository: TodayRepositoryProtocol {
    func fetchDashboard(
        userId: Int64?,
        userAssetProfile: UserAssetProfile,
        portfolioSnapshot: PortfolioSnapshot
    ) async throws -> TodayDashboard {
        Self.makeDashboard(
            userId: userId,
            userAssetProfile: userAssetProfile,
            portfolioSnapshot: portfolioSnapshot
        )
    }

    static func makeDashboard(
        userId: Int64? = nil,
        userAssetProfile: UserAssetProfile,
        portfolioSnapshot: PortfolioSnapshot,
        policyEvents: [TodayPolicyEvent] = TodayMockData.policyEvents,
        holdings: [TodayHolding] = TodayMockData.holdings,
        judgment: TodayJudgment = TodayMockData.judgment
    ) -> TodayDashboard {
        let topPolicy = policyEvents.max { $0.myExposure < $1.myExposure }
        let portfolio = TodayDashboardBuilder.makePortfolioSummary(
            from: portfolioSnapshot,
            userAssetProfile: userAssetProfile,
            fallback: TodayMockData.portfolio
        )

        return TodayDashboard(
            userAssetProfile: userAssetProfile,
            portfolioSnapshot: portfolioSnapshot,
            judgment: judgment,
            portfolio: portfolio,
            policyEvents: policyEvents,
            holdings: holdings,
            noActionReasons: TodayMockData.noActionReasons,
            noActionWatchCondition: TodayMockData.noActionWatchCondition,
            primaryCheckpointText: TodayMockData.checkpoints.first?.text ?? judgment.invalidationCondition,
            dataUpdatedAt: topPolicy?.updatedAt ?? "오전 11:24",
            dataSources: ["예시 데이터"],
            aiSummaryStatus: "예시 브리핑",
            themeSignals: PolSignalFlowMockData.todayThemeSignals,
            policyReadings: PolSignalFlowMockData.policyReadings,
            adjustmentProposal: PolSignalFlowMockData.adjustmentProposal,
            apiConnectionStatuses: Self.mockConnectionStatuses(userId: userId)
        )
    }

    static func mockConnectionStatuses(userId: Int64?) -> [TodayAPIConnectionStatus] {
        let userScoped = userId.map(String.init) ?? "{userId}"

        return [
            TodayAPIConnectionStatus(
                id: "theme-signals",
                title: "내 포트폴리오 Top 3",
                endpoint: "GET /api/users/\(userScoped)/home/briefing",
                detail: userId == nil ? "로그인 사용자 ID가 없어 Mock 데이터 사용 중" : "서버 실패 시 Mock 데이터 사용",
                kind: userId == nil ? .mock : .fallback
            ),
            TodayAPIConnectionStatus(
                id: "policy-readings",
                title: "오늘 읽을 정책 이벤트",
                endpoint: "GET /api/users/\(userScoped)/events",
                detail: userId == nil ? "로그인 사용자 ID가 없어 Mock 데이터 사용 중" : "서버 실패 시 Mock 데이터 사용",
                kind: userId == nil ? .mock : .fallback
            ),
            TodayAPIConnectionStatus(
                id: "adjustment-proposal",
                title: "대응 대기 중",
                endpoint: "백엔드 모델 필요",
                detail: "리밸런싱 제안 모델이 Today 브리핑에 아직 없음",
                kind: .pending
            )
        ]
    }
}
