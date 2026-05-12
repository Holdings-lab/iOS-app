import SwiftUI

@MainActor
struct NewsroomView: View {
    let userAssetProfile: UserAssetProfile

    @StateObject private var viewModel: PolicyNewsViewModel
    @State private var feedMode: NewsroomFeedMode = .news
    @State private var newsFilter: NewsroomNewsFilter = .breaking
    @State private var selectedMarketTicker: NewsroomMarketTicker?
    @State private var selectedArticleItem: PolicyNewsItem?

    init(
        userId: Int64? = nil,
        userAssetProfile: UserAssetProfile,
        viewModel: PolicyNewsViewModel? = nil
    ) {
        self.userAssetProfile = userAssetProfile
        _viewModel = StateObject(wrappedValue: viewModel ?? PolicyNewsViewModel(userId: userId))
    }

    private var displayedItems: [PolicyNewsItem] {
        switch newsFilter {
        case .breaking:
            return viewModel.visibleNews.filter { $0.newsroomRelevanceLevel == .high || $0.sentiment == .caution }
        case .holdings:
            return viewModel.visibleNews.filter(isHoldingRelated)
        }
    }

    private var displayedTickers: [NewsroomMarketTicker] {
        NewsroomMarketData.tickers
    }

    private var learningContents: [NewsroomLearningContent] {
        let categories = assetRelatedCategories
        guard !categories.isEmpty else { return NewsroomLearningContentData.items }

        return NewsroomLearningContentData.items.sorted { lhs, rhs in
            let lhsMatches = categories.contains(lhs.category)
            let rhsMatches = categories.contains(rhs.category)
            if lhsMatches != rhsMatches {
                return lhsMatches
            }

            return lhs.title < rhs.title
        }
    }

    var body: some View {
        PFContentScrollView(
            spacing: 20,
            scrollsToTopOnAppear: true,
            locksHorizontalOverflow: true
        ) {
            NewsroomHeaderView(
                tickers: displayedTickers,
                feedMode: feedMode,
                onTickerTap: { selectedMarketTicker = $0 }
            )

            NewsroomFeedModePicker(selectedMode: $feedMode)

            switch feedMode {
            case .news:
                newsContent
            case .content:
                learningContent
            }

            NewsroomInfoBox(mode: feedMode)
        }
        .policyFinanceLightTabChrome()
        .navigationDestination(item: $selectedMarketTicker) { ticker in
            NewsroomMarketDetailView(
                selectedTicker: ticker,
                quotes: NewsroomMarketData.quotes
            )
        }
        .navigationDestination(item: $selectedArticleItem) { item in
            PolicyNewsArticleDetailView(item: item)
        }
    }

    @ViewBuilder
    private var newsContent: some View {
        NewsroomNewsFilterBar(selectedFilter: $newsFilter)

        if viewModel.isFeedLoading && viewModel.news.isEmpty {
            NewsroomLoadingCard()
        } else if let errorMessage = viewModel.feedErrorMessage, viewModel.news.isEmpty {
            NewsroomErrorCard(message: errorMessage, onRetry: viewModel.loadNews)
        } else if displayedItems.isEmpty {
            NewsroomEmptyCard()
        } else {
            newsroomContent
        }
    }

    private var learningContent: some View {
        NewsroomLearningContentSection(
            title: "투자 학습 콘텐츠",
            subtitle: "\(learningContents.count)개",
            items: learningContents
        )
    }

    private var newsroomContent: some View {
        NewsroomIndustrySummarySection(
            title: newsFilter.title,
            subtitle: "\(displayedItems.count)건",
            items: displayedItems,
            isSaved: viewModel.isSaved,
            onSelect: { item in
                present(item)
            },
            onToggleSave: viewModel.toggleSaved
        )
    }

    private func present(_ item: PolicyNewsItem) {
        selectedArticleItem = item
    }

    private var assetRelatedCategories: Set<PolicyNewsCategory> {
        userAssetProfile.holdings.reduce(into: Set<PolicyNewsCategory>()) { categories, holding in
            let text = normalized(holding.name)

            if holding.category == .depositSavings || holding.category == .loan {
                categories.insert(.interestRate)
                categories.insert(.finance)
            }

            if text.contains("soxx") || text.contains("smh") || text.contains("반도체") || text.contains("삼성") || text.contains("sk") {
                categories.insert(.semiconductor)
            }

            if text.contains("icln") || text.contains("에너지") || text.contains("재생") {
                categories.insert(.energy)
            }

            if text.contains("은행") || text.contains("예금") || text.contains("대출") || text.contains("채권") {
                categories.insert(.interestRate)
                categories.insert(.finance)
            }
        }
    }

    private func isHoldingRelated(_ item: PolicyNewsItem) -> Bool {
        let holdingNames = userAssetProfile.holdings.map { normalized($0.name) }
        let tickerMatches = item.relatedTickers
            .map(normalized)
            .contains { ticker in
                holdingNames.contains { holdingName in
                    !ticker.isEmpty && (holdingName.contains(ticker) || ticker.contains(holdingName))
                }
            }

        return tickerMatches || assetRelatedCategories.contains(item.category)
    }

    private func normalized(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "·", with: "")
            .replacingOccurrences(of: "-", with: "")
    }
}

#Preview {
    NavigationStack {
        NewsroomView(userAssetProfile: AppMockData.userAssetProfile)
    }
}
