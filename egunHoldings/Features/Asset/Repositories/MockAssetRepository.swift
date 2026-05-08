struct MockAssetRepository: AssetRepositoryProtocol {
    func fetchDashboard() -> AssetDashboard {
        AssetMockData.dashboard
    }
}
