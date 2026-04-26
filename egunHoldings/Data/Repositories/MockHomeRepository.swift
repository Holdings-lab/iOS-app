struct MockHomeRepository: HomeRepositoryProtocol {
    func fetchProfile() -> InvestorProfile {
        HomeMockData.profile
    }

    func fetchWeeklyEvents() -> [HomePolicyEvent] {
        HomeMockData.weeklyEvents
    }

    func fetchEventDetails() -> [Int: PolicyEventDetail] {
        HomeMockData.eventDetails
    }

    func fetchUserAssetProfile() -> UserAssetProfile {
        HomeMockData.userAssetProfile
    }

    func fetchPortfolioSnapshot() -> PortfolioSnapshot {
        HomeMockData.snapshot
    }

    func fetchTrendPoints() -> [PortfolioTrendPoint] {
        HomeMockData.trendPoints
    }

    func fetchTrendMarkers() -> [PortfolioMarker] {
        HomeMockData.trendMarkers
    }

    func fetchChartGridValues() -> [Double] {
        HomeMockData.chartGridValues
    }
}
