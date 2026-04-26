protocol HomeRepositoryProtocol {
    func fetchProfile() -> InvestorProfile
    func fetchWeeklyEvents() -> [HomePolicyEvent]
    func fetchEventDetails() -> [Int: PolicyEventDetail]
    func fetchUserAssetProfile() -> UserAssetProfile
    func fetchPortfolioSnapshot() -> PortfolioSnapshot
    func fetchTrendPoints() -> [PortfolioTrendPoint]
    func fetchTrendMarkers() -> [PortfolioMarker]
    func fetchChartGridValues() -> [Double]
}
