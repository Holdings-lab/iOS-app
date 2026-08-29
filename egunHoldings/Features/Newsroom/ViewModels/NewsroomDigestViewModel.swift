import Foundation
import Combine

@MainActor
final class NewsroomDigestViewModel: ObservableObject {
    @Published private(set) var briefing: NewsroomBriefing?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    /// pull-to-refresh 결과 토스트. "이미 최신이에요" 등, 1.5초 뒤 자동으로 사라진다.
    @Published private(set) var refreshStatusMessage: String?

    private var repository: NewsroomDigestRepositoryProtocol

    init(userId: Int64? = nil, repository: NewsroomDigestRepositoryProtocol? = nil) {
        self.repository = repository ?? NewsroomDigestRepositoryFactory.makeDefault(userId: userId)
    }

    func load() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task { [weak self] in
            guard let self else { return }

            do {
                briefing = try await repository.fetchBriefing(briefingDate: nil)
            } catch {
                if briefing == nil {
                    errorMessage = "뉴스룸을 불러오지 못했어요. 잠시 후 다시 시도해주세요."
                }
            }
            isLoading = false
        }
    }

    func loadIfNeeded() {
        guard briefing == nil, !isLoading else { return }
        load()
    }

    @discardableResult
    func refresh() async -> Bool {
        do {
            let fetched = try await repository.fetchBriefing(briefingDate: nil)
            if fetched == briefing {
                await showRefreshStatus("이미 최신이에요")
                return false
            } else {
                briefing = fetched
                errorMessage = nil
                return true
            }
        } catch {
            await showRefreshStatus("새로고침에 실패했어요")
            return false
        }
    }

    /// 상세 화면은 이제 별도 네트워크 요청이라 자체 뷰모델을 새로 만들어 넘긴다.
    func makeDetailViewModel(for holding: NewsroomHoldingBriefing) -> NewsroomTickerDetailViewModel {
        NewsroomTickerDetailViewModel(holding: holding, repository: repository)
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
    func applyScenario(_ scenario: NewsroomDigestScenario) {
        repository = MockNewsroomDigestRepository(scenario: scenario)
        briefing = nil
        load()
    }
    #endif
}
