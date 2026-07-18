import Foundation

protocol NewsroomDigestRepositoryProtocol {
    var showsFirstGenerationState: Bool { get }
    func fetchDigest(userAssetProfile: UserAssetProfile) async throws -> NewsroomDigest
}

extension NewsroomDigestRepositoryProtocol {
    var showsFirstGenerationState: Bool { false }
}
