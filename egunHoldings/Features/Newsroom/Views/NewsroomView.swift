import SwiftUI

@MainActor
struct NewsroomView: View {
    let userAssetProfile: UserAssetProfile

    @StateObject private var viewModel: PolicyNewsViewModel
    @AppStorage("newsroom.selected.categories") private var selectedCategoryStorage = ""
    @State private var selectedCategories: Set<PolicyNewsCategory> = Self.defaultCategories
    @State private var didHydrateSelectedCategories = false
    @State private var isShowingCategoryEditor = false

    init(
        userId: Int64? = nil,
        userAssetProfile: UserAssetProfile,
        viewModel: PolicyNewsViewModel? = nil
    ) {
        self.userAssetProfile = userAssetProfile
        _viewModel = StateObject(wrappedValue: viewModel ?? PolicyNewsViewModel(userId: userId))
    }

    private var displayedItems: [PolicyNewsItem] {
        viewModel.news(matching: selectedCategories)
    }

    private var displayedTickers: [NewsroomMarketTicker] {
        let tickers = NewsroomMarketData.tickers
        guard !selectedCategories.isEmpty else { return tickers }
        return tickers.filter { selectedCategories.contains($0.category) }
    }

    var body: some View {
        PFContentScrollView(
            spacing: 20,
            scrollsToTopOnAppear: true,
            locksHorizontalOverflow: true
        ) {
            NewsroomHeaderView(
                latestUpdateText: displayedItems.first?.relativePublishedText ?? "방금",
                selectedCategoryCount: selectedCategories.isEmpty ? PolicyNewsCategory.allCases.count : selectedCategories.count
            )

            NewsroomMarketTickerTape(tickers: displayedTickers)

            NewsroomCategorySelector(
                selectedCategories: $selectedCategories,
                onEdit: { isShowingCategoryEditor = true }
            )

            if viewModel.isFeedLoading && viewModel.news.isEmpty {
                NewsroomLoadingCard()
            } else if let errorMessage = viewModel.feedErrorMessage, viewModel.news.isEmpty {
                NewsroomErrorCard(message: errorMessage, onRetry: viewModel.loadNews)
            } else if displayedItems.isEmpty {
                NewsroomEmptyCard()
            } else {
                newsroomContent
            }

            NewsroomInfoBox()
        }
        .policyFinanceLightTabChrome()
        .navigationDestination(item: $viewModel.presentedItem) { item in
            PolicyNewsInsightDetailView(
                item: item,
                userAssetProfile: userAssetProfile,
                viewModel: viewModel
            )
        }
        .sheet(isPresented: $isShowingCategoryEditor) {
            NewsroomCategoryEditorSheet(selectedCategories: $selectedCategories)
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.elevated)
            .presentationCornerRadius(KDXRadius.bottomSheet)
        }
        .onAppear {
            hydrateSelectedCategoriesIfNeeded()
        }
        .onChange(of: selectedCategories) { _, newValue in
            persist(newValue)
        }
    }

    @ViewBuilder
    private var newsroomContent: some View {
        NewsroomIndustrySummarySection(
            title: selectedCategories.isEmpty ? "전체 산업 요약" : "관심 산업 요약",
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
        viewModel.presentInsight(
            for: item,
            userAssetProfile: userAssetProfile,
            mode: .quick
        )
    }

    private func hydrateSelectedCategoriesIfNeeded() {
        guard !didHydrateSelectedCategories else { return }
        didHydrateSelectedCategories = true

        let hydrated = Self.decodeCategories(from: selectedCategoryStorage)
        selectedCategories = hydrated.isEmpty ? Self.defaultCategories : hydrated
    }

    private func persist(_ categories: Set<PolicyNewsCategory>) {
        selectedCategoryStorage = categories
            .sorted { $0.title < $1.title }
            .map(\.rawValue)
            .joined(separator: ",")
    }

    private static let defaultCategories: Set<PolicyNewsCategory> = [.semiconductor, .ai, .energy]

    private static func decodeCategories(from storage: String) -> Set<PolicyNewsCategory> {
        Set(
            storage
                .split(separator: ",")
                .compactMap { PolicyNewsCategory(rawValue: String($0)) }
        )
    }
}

#Preview {
    NavigationStack {
        NewsroomView(userAssetProfile: AppMockData.userAssetProfile)
    }
}
