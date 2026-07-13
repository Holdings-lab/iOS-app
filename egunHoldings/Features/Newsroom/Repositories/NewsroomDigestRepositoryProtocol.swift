import Foundation

protocol NewsroomDigestRepositoryProtocol {
    func fetchDigest(userAssetProfile: UserAssetProfile) async throws -> NewsroomDigest
}
