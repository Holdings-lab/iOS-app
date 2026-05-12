import Foundation
import Combine

@MainActor
final class PolicyNewsViewModel: ObservableObject {
    @Published private(set) var news: [PolicyNewsItem] = []
    @Published private(set) var isFeedLoading = false
    @Published private(set) var feedErrorMessage: String?

    @Published var presentedItem: PolicyNewsItem?
    @Published private(set) var presentedInsightMode: NewsroomInsightMode = .quick
    @Published private(set) var presentedInsight: PolicyNewsInsight?
    @Published private(set) var isInsightLoading = false
    @Published private(set) var insightErrorMessage: String?
    @Published private(set) var savedItemIDs: Set<String> = []

    private let repository: PolicyNewsRepositoryProtocol
    private var pendingSummaryRequest: NewsroomPolicySummaryRequest?
    private var pendingSummaryUserAssetProfile: UserAssetProfile?
    private var pendingSummaryMode: NewsroomInsightMode = .quick

    init(userId: Int64? = nil, repository: PolicyNewsRepositoryProtocol? = nil) {
        self.repository = repository ?? PolicyNewsRepositoryFactory.makeDefault(userId: userId)
        loadNews()
    }

    var visibleNews: [PolicyNewsItem] {
        news.sorted { $0.publishedAt > $1.publishedAt }
    }

    func news(matching categories: Set<PolicyNewsCategory>) -> [PolicyNewsItem] {
        guard !categories.isEmpty else { return visibleNews }
        return visibleNews.filter { categories.contains($0.category) }
    }

    func loadNews() {
        guard !isFeedLoading else { return }
        isFeedLoading = true
        feedErrorMessage = nil

        Task { [weak self] in
            guard let self else { return }

            do {
                let items = try await repository.fetchNews()
                applyNews(items)
                isFeedLoading = false
            } catch {
                let fallbackItems = (try? await MockPolicyNewsRepository().fetchNews()) ?? []
                if !fallbackItems.isEmpty {
                    applyNews(fallbackItems)
                    feedErrorMessage = nil
                } else {
                    feedErrorMessage = makeErrorMessage(
                        for: error,
                        fallback: "정책 뉴스를 불러오지 못했어요. 잠시 후 다시 시도해주세요."
                    )
                }
                isFeedLoading = false
            }
        }
    }

    func presentSummary(
        for request: NewsroomPolicySummaryRequest,
        userAssetProfile: UserAssetProfile,
        mode: NewsroomInsightMode = .quick
    ) {
        pendingSummaryRequest = request
        pendingSummaryUserAssetProfile = userAssetProfile
        pendingSummaryMode = mode

        guard !news.isEmpty else {
            if !isFeedLoading {
                loadNews()
            }
            return
        }

        presentPendingSummaryIfNeeded()
    }

    func presentInsight(
        for item: PolicyNewsItem,
        userAssetProfile: UserAssetProfile,
        mode: NewsroomInsightMode = .quick
    ) {
        presentedInsightMode = mode
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

    func toggleSaved(_ item: PolicyNewsItem) {
        if savedItemIDs.contains(item.id) {
            savedItemIDs.remove(item.id)
        } else {
            savedItemIDs.insert(item.id)
        }
    }

    func isSaved(_ item: PolicyNewsItem) -> Bool {
        savedItemIDs.contains(item.id)
    }

    func dismissPresentedInsight() {
        presentedItem = nil
        presentedInsight = nil
        insightErrorMessage = nil
        isInsightLoading = false
    }

    private func applyNews(_ items: [PolicyNewsItem]) {
        news = items
        presentPendingSummaryIfNeeded()
    }

    private func presentPendingSummaryIfNeeded() {
        guard let request = pendingSummaryRequest,
              let userAssetProfile = pendingSummaryUserAssetProfile,
              let item = bestNewsItem(matching: request)
        else {
            return
        }

        pendingSummaryRequest = nil
        pendingSummaryUserAssetProfile = nil
        let mode = pendingSummaryMode
        pendingSummaryMode = .quick
        presentInsight(for: item, userAssetProfile: userAssetProfile, mode: mode)
    }

    private func bestNewsItem(matching request: NewsroomPolicySummaryRequest) -> PolicyNewsItem? {
        visibleNews
            .map { item in
                (item: item, score: matchScore(item, request: request))
            }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score {
                    return lhs.score > rhs.score
                }

                return lhs.item.publishedAt > rhs.item.publishedAt
            }
            .first { $0.score > 0 }?
            .item ?? visibleNews.first
    }

    private func matchScore(_ item: PolicyNewsItem, request: NewsroomPolicySummaryRequest) -> Int {
        let searchableText = normalizedText(
            ([item.title, item.summary] + item.relatedTickers).joined(separator: " ")
        )
        let policyTitle = normalizedText(request.policyTitle)
        let titleTokens = policyTitle
            .split(separator: " ")
            .map(String.init)
            .filter { $0.count >= 2 }

        let assetScore = request.relatedAssets.reduce(0) { score, asset in
            let normalizedAsset = normalizedText(asset)
            guard !normalizedAsset.isEmpty else { return score }

            return searchableText.contains(normalizedAsset) ? score + 40 : score
        }

        let titleScore = titleTokens.reduce(0) { score, token in
            searchableText.contains(token) ? score + 12 : score
        }

        let categoryScore = policyTitle.contains(item.category.title.lowercased()) ? 12 : 0

        return assetScore + titleScore + categoryScore
    }

    private func normalizedText(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "·", with: " ")
            .replacingOccurrences(of: "…", with: " ")
            .replacingOccurrences(of: "...", with: " ")
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
