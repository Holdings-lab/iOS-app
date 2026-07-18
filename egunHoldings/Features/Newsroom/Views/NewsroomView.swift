import SwiftUI
import UIKit

/// 보유 종목 24시간 뉴스를 종목 단위로 종합한 유한한 일일 브리핑.
@MainActor
struct NewsroomView: View {
    let userAssetProfile: UserAssetProfile
    var onAssetTabRequested: () -> Void = {}

    @StateObject private var viewModel: NewsroomDigestViewModel
    @State private var presentedTickerDigest: NewsroomTickerDigest?

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

                if userAssetProfile.holdings.isEmpty {
                    NewsroomNoHoldingsCard(onRegister: onAssetTabRequested)
                } else if viewModel.isPreparingFirstBriefing {
                    NewsroomFirstGenerationCard(holdingCount: userAssetProfile.holdings.count)
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
                let didUpdate = await viewModel.refresh(userAssetProfile: userAssetProfile)
                if didUpdate {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }

            if let refreshStatusMessage = viewModel.refreshStatusMessage {
                refreshToast(refreshStatusMessage)
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.refreshStatusMessage)
        .policyFinanceLightTabChrome()
        .navigationDestination(item: $presentedTickerDigest) { digest in
            NewsroomDigestDetailView(
                digest: digest,
                referenceText: viewModel.digest?.referenceText ?? ""
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("뉴스룸")
                .font(.pretendard(22, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .tracking(-0.5)

            if let digest = viewModel.digest {
                Text("\(digest.referenceText) · \(digest.nextUpdateText)")
                    .font(.pretendard(12.5, weight: .medium))
                    .foregroundStyle(digest.isOffline ? Color.warning : Color.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("보유 자산의 지난 24시간을 하나의 브리핑으로 정리해요")
                    .font(.pretendard(12.5, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func digestContent(_ digest: NewsroomDigest) -> some View {
        if let macroIssue = digest.macroIssue {
            NewsroomMacroIssueBanner(issue: macroIssue)
        }

        tickerSection(digest)

        NewsroomEndMarker(heartbeatText: nil)
    }

    private func tickerSection(_ digest: NewsroomDigest) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("내 보유 종목")
                .font(.pretendard(16, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            ForEach(digest.sortedTickerDigests) { tickerDigest in
                NewsroomTickerDigestRow.make(
                    for: tickerDigest,
                    isHero: digest.heroTickerIDs.contains(tickerDigest.id)
                ) {
                    presentedTickerDigest = tickerDigest
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

#Preview("뉴스 혼재") {
    NavigationStack {
        NewsroomView(
            userAssetProfile: AppMockData.userAssetProfile,
            viewModel: NewsroomDigestViewModel(
                repository: MockNewsroomDigestRepository(scenario: .calmMixed)
            )
        )
    }
}

#Preview("포트폴리오 공통 이슈") {
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
