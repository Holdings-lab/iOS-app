import Foundation

nonisolated enum NewsroomDigestRepositoryFactory {
    /// 다이제스트 API 스펙이 확정되기 전까지 Mock을 반환한다.
    /// UI/UX 확정 후 LiveNewsroomDigestRepository로 교체한다.
    static func makeDefault(userId: Int64? = nil) -> NewsroomDigestRepositoryProtocol {
        // UI/UX 검증 중 — 뉴스가 있는 화면(히어로/컴팩트/조용 혼재)을 기본으로 표시.
        // 검증 후 기본값을 .calmAllQuiet로 되돌릴 것.
        MockNewsroomDigestRepository(scenario: .calmMixed)
    }
}
