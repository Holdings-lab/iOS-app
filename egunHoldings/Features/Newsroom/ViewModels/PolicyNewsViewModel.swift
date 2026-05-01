import Foundation
import Combine

@MainActor
final class PolicyNewsViewModel: ObservableObject {
    @Published private(set) var news: [PolicyNewsItem] = []
    @Published private(set) var isFeedLoading = false
    @Published private(set) var feedErrorMessage: String?

    @Published var presentedItem: PolicyNewsItem?
    @Published private(set) var presentedInsight: PolicyNewsInsight?
    @Published private(set) var isInsightLoading = false
    @Published private(set) var insightErrorMessage: String?

    private let repository: PolicyNewsRepositoryProtocol

    init(repository: PolicyNewsRepositoryProtocol? = nil) {
        self.repository = repository ?? PolicyNewsRepositoryFactory.makeDefault()
        loadNews()
    }

    func loadNews() {
        guard !isFeedLoading else { return }
        isFeedLoading = true
        feedErrorMessage = nil

        Task { [weak self] in
            guard let self else { return }

            do {
                let items = try await repository.fetchNews()
                news = items
                isFeedLoading = false
            } catch {
                feedErrorMessage = makeErrorMessage(
                    for: error,
                    fallback: "정책 뉴스를 불러오지 못했어요. 잠시 후 다시 시도해주세요."
                )
                isFeedLoading = false
            }
        }
    }

    func presentInsight(for item: PolicyNewsItem, userAssetProfile: UserAssetProfile) {
        presentedItem = item
        presentedInsight = nil
        insightErrorMessage = nil
        loadInsight(for: item, userAssetProfile: userAssetProfile)
    }

    func reloadPresentedInsight(userAssetProfile: UserAssetProfile) {
        guard let presentedItem else { return }
        presentedInsight = nil
        insightErrorMessage = nil
        loadInsight(for: presentedItem, userAssetProfile: userAssetProfile)
    }

    func dismissPresentedInsight() {
        presentedItem = nil
        presentedInsight = nil
        insightErrorMessage = nil
        isInsightLoading = false
    }

    private func loadInsight(for item: PolicyNewsItem, userAssetProfile: UserAssetProfile) {
        guard !isInsightLoading else { return }
        isInsightLoading = true

        Task { [weak self] in
            guard let self else { return }

            do {
                let insight = try await repository.fetchInsight(for: item, userAssetProfile: userAssetProfile)
                guard presentedItem?.id == item.id else { return }
                presentedInsight = insight
                isInsightLoading = false
            } catch {
                guard presentedItem?.id == item.id else { return }
                insightErrorMessage = makeErrorMessage(
                    for: error,
                    fallback: "맞춤 해설을 만드는 데 실패했어요. 잠시 후 다시 시도해주세요."
                )
                isInsightLoading = false
            }
        }
    }

    private func makeErrorMessage(for error: Error, fallback: String) -> String {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .apiFailure(_, _, let message):
                return message
            case .httpStatus(let statusCode):
                return "서버 응답이 올바르지 않았어요. 상태 코드: \(statusCode)"
            case .invalidURL:
                return "백엔드 주소 설정이 올바르지 않아요."
            default:
                return fallback
            }
        }

        return fallback
    }
}
