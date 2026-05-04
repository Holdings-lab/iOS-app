import Foundation

protocol PolicyNewsRepositoryProtocol {
    func fetchNews() async throws -> [PolicyNewsItem]
    func fetchInsight(for item: PolicyNewsItem, userAssetProfile: UserAssetProfile) async throws -> PolicyNewsInsight
}
