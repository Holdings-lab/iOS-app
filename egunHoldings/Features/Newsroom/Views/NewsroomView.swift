import SwiftUI
import UIKit

/// 보유 종목 뉴스를 종목 단위로 종합한 일일 브리핑.
/// 빈 자산 여부는 더 이상 클라이언트가 미리 판단하지 않는다 — 서버 응답의 emptyState가 기준이다
/// (holdings가 비어 있으면 서버가 항상 emptyState를 함께 내려준다, NewsroomService.emptyTabResponse).
@MainActor
struct NewsroomView: View {
    let userAssetProfile: UserAssetProfile
    var onAssetTabRequested: () -> Void = {}

    @StateObject private var viewModel: NewsroomDigestViewModel
    @State private var presentedHolding: NewsroomHoldingBriefing?

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

                if let briefing = viewModel.briefing, briefing.holdings.isEmpty {
                    NewsroomNoHoldingsCard(onRegister: onAssetTabRequested)
                } else if let briefing = viewModel.briefing, briefing.hasNoRelevantNews {
                    NewsroomNoRelatedNewsCard()
                } else if viewModel.isLoading && viewModel.briefing == nil {
                    NewsroomDigestSkeleton()
                } else if let errorMessage = viewModel.errorMessage, viewModel.briefing == nil {
                    NewsroomErrorCard(message: errorMessage) {
                        viewModel.load()
                    }
                } else if let briefing = viewModel.briefing {
                    briefingContent(briefing)
                }
            }
            .refreshable {
                await viewModel.refresh()
            }

            if let refreshStatusMessage = viewModel.refreshStatusMessage {
                refreshToast(refreshStatusMessage)
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.refreshStatusMessage)
        .policyFinanceLightTabChrome()
        .navigationDestination(item: $presentedHolding) { holding in
            NewsroomDigestDetailView(viewModel: viewModel.makeDetailViewModel(for: holding))
        }
        .onAppear {
            viewModel.loadIfNeeded()
        }
        #if DEBUG
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                scenarioMenu
            }
        }
        #endif
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("뉴스룸")
                .font(.pretendard(22, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .tracking(-0.5)

            if let briefing = viewModel.briefing {
                Text([briefing.asOfAtText, briefing.subtitle].compactMap { $0 }.joined(separator: " · "))
                    .font(.pretendard(12.5, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("보유 자산의 최근 소식을 하나의 브리핑으로 정리해요")
                    .font(.pretendard(12.5, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func briefingContent(_ briefing: NewsroomBriefing) -> some View {
        tickerSection(briefing)

        NewsroomEndMarker(heartbeatText: nil)
    }

    private func tickerSection(_ briefing: NewsroomBriefing) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("내 보유 종목")
                .font(.pretendard(16, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            ForEach(briefing.holdings) { holding in
                NewsroomTickerDigestRow.make(for: holding) {
                    presentedHolding = holding
                }
            }
        }
    }

    private func refreshToast(_ message: String) -> some View {
        Text(message)
            .font(.pretendard(12.5, weight: .semibold))
            .foregroundStyle(Color.textOnAccent)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(Color.textPrimary.opacity(0.88), in: Capsule())
            .frame(maxWidth: .infinity)
    }

    #if DEBUG
    private var scenarioMenu: some View {
        Menu {
            ForEach(NewsroomDigestScenario.allCases) { scenario in
                Button(scenario.title) {
                    viewModel.applyScenario(scenario)
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

#Preview("뉴스 혼재") {
    NavigationStack {
        NewsroomView(
            userAssetProfile: AppMockData.userAssetProfile,
            viewModel: NewsroomDigestViewModel(
                repository: MockNewsroomDigestRepository(scenario: .mixed)
            )
        )
    }
}

#Preview("전 종목 조용") {
    NavigationStack {
        NewsroomView(
            userAssetProfile: AppMockData.userAssetProfile,
            viewModel: NewsroomDigestViewModel(
                repository: MockNewsroomDigestRepository(scenario: .allQuiet)
            )
        )
    }
}

#Preview("종목 0개") {
    NavigationStack {
        NewsroomView(
            userAssetProfile: UserAssetProfile(holdings: []),
            viewModel: NewsroomDigestViewModel(
                repository: MockNewsroomDigestRepository(scenario: .empty)
            )
        )
    }
}
