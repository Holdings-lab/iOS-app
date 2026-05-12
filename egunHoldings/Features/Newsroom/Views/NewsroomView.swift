import SwiftUI

@MainActor
struct NewsroomView: View {
    let userAssetProfile: UserAssetProfile
    let summaryRequest: NewsroomPolicySummaryRequest?

    @StateObject private var viewModel: PolicyNewsViewModel
    @State private var digestMode: NewsroomDigestMode = .oneMinute
    @State private var handledSummaryRequestID: UUID?

    init(
        userId: Int64? = nil,
        userAssetProfile: UserAssetProfile,
        summaryRequest: NewsroomPolicySummaryRequest? = nil,
        viewModel: PolicyNewsViewModel? = nil
    ) {
        self.userAssetProfile = userAssetProfile
        self.summaryRequest = summaryRequest
        _viewModel = StateObject(wrappedValue: viewModel ?? PolicyNewsViewModel(userId: userId))
    }

    private var displayedItems: [PolicyNewsItem] {
        viewModel.visibleNews
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
        .sheet(item: $viewModel.lowRelevanceItem, onDismiss: viewModel.dismissLowRelevanceReason) { item in
            LowRelevanceSheet(
                item: item,
                onOpen: {
                    viewModel.dismissLowRelevanceReason()
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 220_000_000)
                        viewModel.presentInsight(for: item, userAssetProfile: userAssetProfile)
                    }
                }
            )
            .presentationDetents([.fraction(0.42), .medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.elevated)
            .presentationCornerRadius(KDXRadius.bottomSheet)
        }
        .onAppear {
            handleSummaryRequestIfNeeded()
        }
        .onChange(of: summaryRequest?.id) { _, _ in
            handleSummaryRequestIfNeeded()
        }
    }

    @ViewBuilder
    private var newsroomContent: some View {
        if digestMode == .saved {
            NewsroomSavedSection(
                items: viewModel.savedNews,
                onSelect: { item in
                    viewModel.presentInsight(for: item, userAssetProfile: userAssetProfile)
                }
            )
        } else {
            if !viewModel.highRelevanceNews.isEmpty {
                NewsroomPrioritySection(
                    title: "내 자산 관련",
                    subtitle: "\(viewModel.highRelevanceNews.count)건",
                    items: viewModel.highRelevanceNews,
                    presentation: digestMode == .oneMinute ? .skim : .detail,
                    isSaved: viewModel.isSaved,
                    onSelect: { item in
                        viewModel.presentInsight(for: item, userAssetProfile: userAssetProfile)
                    },
                    onToggleSave: viewModel.toggleSaved,
                    onShowLowReason: viewModel.presentLowRelevanceReason
                )
            }

            if !viewModel.mediumRelevanceNews.isEmpty {
                NewsroomPrioritySection(
                    title: "짧게 확인",
                    subtitle: "\(viewModel.mediumRelevanceNews.count)건",
                    items: viewModel.mediumRelevanceNews,
                    presentation: .skim,
                    isSaved: viewModel.isSaved,
                    onSelect: { item in
                        viewModel.presentInsight(for: item, userAssetProfile: userAssetProfile)
                    },
                    onToggleSave: viewModel.toggleSaved,
                    onShowLowReason: viewModel.presentLowRelevanceReason
                )
            }

            if !viewModel.lowRelevanceNews.isEmpty {
                NewsroomPrioritySection(
                    title: "지금은 넘겨도 됨",
                    subtitle: "\(viewModel.lowRelevanceNews.count)건",
                    items: viewModel.lowRelevanceNews,
                    presentation: .ignore,
                    isSaved: viewModel.isSaved,
                    onSelect: { item in
                        viewModel.presentInsight(for: item, userAssetProfile: userAssetProfile)
                    },
                    onToggleSave: viewModel.toggleSaved,
                    onShowLowReason: viewModel.presentLowRelevanceReason
                )
            }
        }
    }

    private func handleSummaryRequestIfNeeded() {
        guard let summaryRequest,
              handledSummaryRequestID != summaryRequest.id
        else {
            return
        }

        handledSummaryRequestID = summaryRequest.id
        digestMode = .oneMinute
        viewModel.presentSummary(for: summaryRequest, userAssetProfile: userAssetProfile)
    }
}

#Preview {
    NavigationStack {
        NewsroomView(userAssetProfile: AppMockData.userAssetProfile)
    }
}
