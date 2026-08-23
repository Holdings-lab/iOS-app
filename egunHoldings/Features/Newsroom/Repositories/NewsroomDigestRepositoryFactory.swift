import Foundation

nonisolated enum NewsroomDigestRepositoryFactory {
    /// 서버(NewsroomController)가 실제 배포되어 Live로 전환했다 — Mock을 쓰려면 호출부에서
    /// `NewsroomDigestViewModel(repository: MockNewsroomDigestRepository(scenario: ...))`로 직접 주입한다.
    static func makeDefault(userId: Int64? = nil) -> NewsroomDigestRepositoryProtocol {
        guard userId != nil else {
            return MockNewsroomDigestRepository(scenario: .mixed)
        }
        return LiveNewsroomDigestRepository()
    }
}
