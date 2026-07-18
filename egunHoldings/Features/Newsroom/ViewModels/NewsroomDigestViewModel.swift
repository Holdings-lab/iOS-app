import Foundation
import Combine

@MainActor
final class NewsroomDigestViewModel: ObservableObject {
    @Published private(set) var digest: NewsroomDigest?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    /// pull-to-refresh 결과 토스트. "이미 최신이에요" 등, 1.5초 뒤 자동으로 사라진다.
    @Published private(set) var refreshStatusMessage: String?

    var isPreparingFirstBriefing: Bool {
        isLoading && digest == nil && repository.showsFirstGenerationState
    }

    private var repository: NewsroomDigestRepositoryProtocol

    init(userId: Int64? = nil, repository: NewsroomDigestRepositoryProtocol? = nil) {
        self.repository = repository ?? NewsroomDigestRepositoryFactory.makeDefault(userId: userId)
    }

    func load(userAssetProfile: UserAssetProfile) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task { [weak self] in
            guard let self else { return }

            do {
                digest = try await repository.fetchDigest(userAssetProfile: userAssetProfile)
            } catch {
                if digest == nil {
                    errorMessage = "다이제스트를 불러오지 못했어요. 잠시 후 다시 시도해주세요."
                }
            }
            isLoading = false
        }
    }

    func loadIfNeeded(userAssetProfile: UserAssetProfile) {
        guard digest == nil, !isLoading else { return }
        load(userAssetProfile: userAssetProfile)
    }

    /// Pull-to-refresh. LLM 생성을 트리거하지 않는다 — 같은 다이제스트면 "이미 최신이에요" 토스트만 보여준다.
    @discardableResult
    func refresh(userAssetProfile: UserAssetProfile) async -> Bool {
        do {
            let fetched = try await repository.fetchDigest(userAssetProfile: userAssetProfile)
            if fetched == digest {
                await showRefreshStatus("이미 최신이에요")
                return false
            } else {
                digest = fetched
                errorMessage = nil
                return true
            }
        } catch {
            await showRefreshStatus("새로고침에 실패했어요")
            return false
        }
    }

    private func showRefreshStatus(_ message: String) async {
        refreshStatusMessage = message
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        if refreshStatusMessage == message {
            refreshStatusMessage = nil
        }
    }

    #if DEBUG
    /// UI/UX 검증용 — Mock 시나리오를 바꿔가며 화면 상태를 확인한다.
    func applyScenario(_ scenario: NewsroomDigestScenario, userAssetProfile: UserAssetProfile) {
        repository = MockNewsroomDigestRepository(scenario: scenario)
        digest = nil
        load(userAssetProfile: userAssetProfile)
    }
    #endif
}
