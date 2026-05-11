enum AssetRebalancingRepositoryFactory {
    static func makeDefault() -> AssetRebalancingRepositoryProtocol {
        LiveAssetRebalancingRepository()
    }
}
