import SwiftUI

/// 뉴스룸 — 이해의 공간.
/// 오늘탭 = 사실(무슨 일이 있었나) / 뉴스룸 = 이해(왜, 나에게 무슨 의미인가).
/// 무한 스크롤·페이지네이션 없음. 콘텐츠는 항상 유한하고, 끝이 보인다 (§1.6).
@MainActor
struct NewsroomView: View {
    let userAssetProfile: UserAssetProfile
    var onAssetTabRequested: () -> Void = {}

    @StateObject private var viewModel: NewsroomDigestViewModel
    @State private var presentedDetailContent: NewsroomDetailContent?
    @State private var presentedLearningContent: NewsroomLearningContent?

    init(
        userId: Int64? = nil,
        userAssetProfile: UserAssetProfile,
        onAssetTabRequested: @escaping () -> Void = {},
        viewModel: NewsroomDigestViewModel? = nil
    ) {
        self.userAssetProfile = userAssetProfile
        self.onAssetTabRequested = onAssetTabRequested
        _viewModel = StateObject(wrappedValue: viewModel ?? NewsroomDigestViewModel(userId: userId))
    }

    var body: some View {
        ZStack(alignment: .top) {
            PFContentScrollView(
                spacing: 20,
                scrollsToTopOnAppear: true,
                locksHorizontalOverflow: true
            ) {
                header

                // 보유 종목 0은 payload가 아니라 프로필로 판단한다 — 다이제스트 요청 자체를 하지 않는다.
                if userAssetProfile.holdings.isEmpty {
                    noHoldingsCard
                } else if viewModel.isLoading && viewModel.digest == nil {
                    NewsroomDigestSkeleton()
                } else if let errorMessage = viewModel.errorMessage, viewModel.digest == nil {
                    NewsroomErrorCard(message: errorMessage) {
                        viewModel.load(userAssetProfile: userAssetProfile)
                    }
                } else if let digest = viewModel.digest {
                    digestContent(digest)
                }
            }
            .refreshable {
                guard !userAssetProfile.holdings.isEmpty else { return }
                await viewModel.refresh(userAssetProfile: userAssetProfile)
            }

            if let refreshStatusMessage = viewModel.refreshStatusMessage {
                refreshToast(refreshStatusMessage)
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.refreshStatusMessage)
        .policyFinanceLightTabChrome()
        .navigationDestination(item: $presentedDetailContent) { content in
            NewsroomDigestDetailView(
                content: content,
                severity: viewModel.digest?.severity ?? .calm,
                referenceText: viewModel.digest?.referenceText ?? "",
                relatedLearningContent: relatedLearningContent(for: content),
                onSelectLearningContent: { presentedLearningContent = $0 }
            )
        }
        .sheet(item: $presentedLearningContent) { item in
            NewsroomLearningCardDetailSheet(
                item: item,
                relatedDigest: viewModel.relatedDigestContent(for: item),
                onOpenRelatedDigest: { presentedDetailContent = $0 }
            )
        }
        .onAppear {
            guard !userAssetProfile.holdings.isEmpty else { return }
            viewModel.loadIfNeeded(userAssetProfile: userAssetProfile)
        }
        #if DEBUG
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                scenarioMenu
            }
        }
        #endif
    }

    // MARK: - Header (§1.1 — 타이틀 + 기준 시각 라인은 항상 노출)

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("뉴스룸")
                .font(.pretendard(22, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .tracking(-0.5)

            if let digest = viewModel.digest, !userAssetProfile.holdings.isEmpty {
                Text("\(digest.referenceText) · \(digest.nextUpdateText)")
                    .font(.pretendard(12.5, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            } else {
                Text("무슨 일이 있었는지, 나에게 어떤 의미인지")
                    .font(.pretendard(12.5, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Digest Content

    @ViewBuilder
    private func digestContent(_ digest: NewsroomDigest) -> some View {
        // 1. 상태 브리핑
        NewsroomBriefingCard(digest: digest) {
            if let marketStory = digest.marketStory {
                presentedDetailContent = .marketStory(marketStory, portfolioTodayChangePercent: digest.portfolioTodayChangePercent)
            }
        }

        // 2. 시장 공통 스토리 — watch/alert는 상단 브리핑이 같은 상세 진입을 맡아 중복을 피한다.
        switch digest.severity {
        case .calm:
            if let marketStory = digest.marketStory {
                NewsroomMarketStoryCard(story: marketStory) {
                    presentedDetailContent = .marketStory(marketStory, portfolioTodayChangePercent: digest.portfolioTodayChangePercent)
                }
            }
        case .watch, .alert:
            EmptyView()
        }

        // 3. 내 종목 — materiality high → low → 조용 순
        if !digest.tickerDigests.isEmpty {
            tickerSection(digest)
        }

        // 4. 학습 콘텐츠 — 독립 피드가 아니라 오늘 이야기와 페어링
        let learningItems = viewModel.pairedLearningContents()
        if !learningItems.isEmpty {
            NewsroomLearningCardRail(items: learningItems) { presentedLearningContent = $0 }
        }

        // 종료 마커 — 이 아래엔 아무것도 두지 않는다
        NewsroomEndMarker(heartbeatText: digest.heartbeatText)
    }

    private func tickerSection(_ digest: NewsroomDigest) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("내 종목")
                .font(.pretendard(16, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            ForEach(digest.sortedTickerDigests) { tickerDigest in
                NewsroomTickerDigestRow.make(for: tickerDigest) {
                    presentedDetailContent = .ticker(tickerDigest)
                }
            }
        }
    }

    // MARK: - 종목 0개 (§4.4)

    private var noHoldingsCard: some View {
        TodayEmptyStateCard(
            iconName: "newspaper",
            title: "종목을 등록하면 관련 소식을 모아드려요",
            subtitle: "보유 종목을 등록하면 그 종목과 관련된 이야기만 정리해서 보여드려요.",
            ctaTitle: "종목 등록하기",
            onCTA: onAssetTabRequested
        )
    }

    // MARK: - Pull-to-refresh 토스트 (§4.1)

    private func refreshToast(_ message: String) -> some View {
        Text(message)
            .font(.pretendard(12.5, weight: .semibold))
            .foregroundStyle(Color.textOnAccent)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(Color.textPrimary.opacity(0.88), in: Capsule())
            .frame(maxWidth: .infinity)
    }

    // MARK: - 학습 카드 역링크 매칭

    private func relatedLearningContent(for content: NewsroomDetailContent) -> NewsroomLearningContent? {
        let topics: Set<PolicyNewsCategory>
        switch content {
        case .ticker(let digest):
            topics = Set(digest.topicCategories)
        case .marketStory(let story, _):
            topics = Set(story.topicCategories)
        }

        guard !topics.isEmpty else { return nil }
        return viewModel.digest?.learningCards.first { topics.contains($0.category) }
    }

    #if DEBUG
    /// UI/UX 검증용 Mock 시나리오 전환 메뉴 — 릴리스 빌드에는 포함되지 않는다.
    private var scenarioMenu: some View {
        Menu {
            ForEach(NewsroomDigestScenario.allCases) { scenario in
                Button(scenario.title) {
                    viewModel.applyScenario(scenario, userAssetProfile: userAssetProfile)
                }
            }
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textTertiary)
        }
    }
    #endif
}

#Preview("조용한 주간 (기본)") {
    NavigationStack {
        NewsroomView(
            userAssetProfile: AppMockData.userAssetProfile,
            viewModel: NewsroomDigestViewModel(
                repository: MockNewsroomDigestRepository(scenario: .calmAllQuiet)
            )
        )
    }
}

#Preview("일부 종목 뉴스") {
    NavigationStack {
        NewsroomView(
            userAssetProfile: AppMockData.userAssetProfile,
            viewModel: NewsroomDigestViewModel(
                repository: MockNewsroomDigestRepository(scenario: .calmMixed)
            )
        )
    }
}

#Preview("변동 이슈 발생") {
    NavigationStack {
        NewsroomView(
            userAssetProfile: AppMockData.userAssetProfile,
            viewModel: NewsroomDigestViewModel(
                repository: MockNewsroomDigestRepository(scenario: .alert)
            )
        )
    }
}

#Preview("종목 0개") {
    NavigationStack {
        NewsroomView(
            userAssetProfile: UserAssetProfile(holdings: []),
            viewModel: NewsroomDigestViewModel(
                repository: MockNewsroomDigestRepository(scenario: .calmAllQuiet)
            )
        )
    }
}
