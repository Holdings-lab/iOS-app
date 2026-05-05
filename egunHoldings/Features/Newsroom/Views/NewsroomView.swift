import SwiftUI

@MainActor
struct NewsroomView: View {
    let userAssetProfile: UserAssetProfile

    @StateObject private var viewModel: PolicyNewsViewModel
    @State private var digestMode: NewsroomDigestMode = .oneMinute

    init(
        userAssetProfile: UserAssetProfile,
        viewModel: PolicyNewsViewModel? = nil
    ) {
        self.userAssetProfile = userAssetProfile
        _viewModel = StateObject(wrappedValue: viewModel ?? PolicyNewsViewModel())
    }

    private var displayedItems: [PolicyNewsItem] {
        guard let limit = digestMode.storyLimit else {
            return viewModel.news
        }

        return Array(viewModel.news.prefix(limit))
    }

    private var spotlightItem: PolicyNewsItem? {
        displayedItems.first
    }

    private var assetLinkedItems: [PolicyNewsItem] {
        displayedItems.filter { item in
            item.id != spotlightItem?.id && !item.relatedTickers.isEmpty
        }
    }

    private var skimmableItems: [PolicyNewsItem] {
        displayedItems.filter { item in
            item.id != spotlightItem?.id && !assetLinkedItems.contains(where: { $0.id == item.id })
        }
    }

    var body: some View {
        PFContentScrollView(spacing: 20, scrollsToTopOnAppear: true) {
            NewsroomHeaderView(
                latestUpdateText: displayedItems.first?.relativePublishedText ?? "방금",
                digestMode: $digestMode
            )

            if viewModel.isFeedLoading && viewModel.news.isEmpty {
                NewsroomLoadingCard()
            } else if let errorMessage = viewModel.feedErrorMessage, viewModel.news.isEmpty {
                NewsroomErrorCard(message: errorMessage, onRetry: viewModel.loadNews)
            } else if displayedItems.isEmpty {
                NewsroomEmptyCard()
            } else {
                if let spotlightItem {
                    NewsroomSpotlightCard(item: spotlightItem) {
                        viewModel.presentInsight(for: spotlightItem, userAssetProfile: userAssetProfile)
                    }
                }

                if !assetLinkedItems.isEmpty {
                    NewsroomCapsuleSection(
                        title: "내 자산 관련",
                        subtitle: "보유 자산과 직접 연결되는 이슈만 먼저 모았어요",
                        items: assetLinkedItems,
                        style: .linked,
                        onSelect: { item in
                            viewModel.presentInsight(for: item, userAssetProfile: userAssetProfile)
                        }
                    )
                }

                if !skimmableItems.isEmpty {
                    NewsroomCapsuleSection(
                        title: "짧게 보고 저장",
                        subtitle: "지금은 제목과 한 줄 요약만 체크해도 되는 이슈예요",
                        items: skimmableItems,
                        style: .skim,
                        onSelect: { item in
                            viewModel.presentInsight(for: item, userAssetProfile: userAssetProfile)
                        }
                    )
                }
            }
        }
        .policyFinanceDarkTabChrome()
        .sheet(item: $viewModel.presentedItem, onDismiss: viewModel.dismissPresentedInsight) { item in
            PolicyNewsInsightSheet(
                item: item,
                insight: viewModel.presentedInsight,
                isLoading: viewModel.isInsightLoading,
                errorMessage: viewModel.insightErrorMessage,
                onRetry: {
                    viewModel.reloadPresentedInsight(userAssetProfile: userAssetProfile)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(.clear)
            .presentationCornerRadius(28)
        }
    }
}

#Preview {
    NavigationStack {
        NewsroomView(userAssetProfile: HomeMockData.userAssetProfile)
    }
}
