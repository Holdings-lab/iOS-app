import SwiftUI

@MainActor
struct HomeView: View {
    let viewModel: HomeViewModel
    @State private var quickSheetPolicyID: Int?
    @State private var detailSheetRoute: HomePolicyDetailRoute?

    init(viewModel: HomeViewModel? = nil) {
        self.viewModel = viewModel ?? HomeViewModel()
    }

    var body: some View {
        ZStack {
            homeBackground

            PFContentScrollView(spacing: 24, topPadding: 14, scrollsToTopOnAppear: true) {
                HomeHeaderView(profile: viewModel.profile)
                    .padding(.bottom, 2)

                if let policy = viewModel.briefingPolicy {
                    HomeBriefingCard(
                        policy: policy,
                        actionText: viewModel.homeBriefingAction(for: policy),
                        changeText: viewModel.snapshot.changePercentText,
                        signalCountText: "\(viewModel.activeSignalCount)건",
                        onTap: {
                            quickSheetPolicyID = policy.id
                        }
                    )
                }

                HomePortfolioSummaryCard(
                    snapshot: viewModel.snapshot,
                    riskTitle: viewModel.homeRiskTitle,
                    riskReason: viewModel.homeRiskReason,
                    exposureItems: viewModel.homeExposureItems,
                    exposureTitle: viewModel.homeExposureTitle(for:)
                )

                HomeSecondaryPolicySection(
                    policies: followUpPolicies,
                    onSelect: { policy in
                        quickSheetPolicyID = policy.id
                    }
                )
            }
        }
        .policyFinanceNavigationChrome(bottomInset: 104)
        .navigationDestination(item: $quickSheetPolicyID) { policyID in
            if let policy = viewModel.impactPolicy(for: policyID) {
                QuickInterpretationSheet(
                    policy: policy,
                    checkValue: viewModel.quickCheckValue(for: policy),
                    checkHint: viewModel.quickCheckHint(for: policy),
                    onOpenDetail: {
                        detailSheetRoute = HomePolicyDetailRoute(
                            policyID: policy.id,
                            initialTab: .evidence
                        )
                    }
                )
            }
        }
        .sheet(item: $detailSheetRoute) { route in
            if let policy = viewModel.impactPolicy(for: route.policyID) {
                PolicyImpactDetailSheet(policy: policy, initialTab: route.initialTab)
                    .presentationDetents([.fraction(0.92)])
                    .presentationDragIndicator(.hidden)
                    .presentationBackground(.clear)
                    .presentationCornerRadius(28)
            } else {
                Color.clear
            }
        }
    }

    private var homeBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "060B24"),
                    Color(hex: "0D163B"),
                    Color(hex: "060B24")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.electricBlue.opacity(0.16))
                .frame(width: 320, height: 320)
                .blur(radius: 120)
                .offset(x: -120, y: -330)

            Circle()
                .fill(Color.policyPurple.opacity(0.12))
                .frame(width: 250, height: 250)
                .blur(radius: 110)
                .offset(x: 160, y: -230)

            Circle()
                .fill(Color.white.opacity(0.04))
                .frame(width: 220, height: 220)
                .blur(radius: 90)
                .offset(x: 120, y: 250)
        }
        .ignoresSafeArea()
    }

    private var followUpPolicies: [HomeImpactPolicy] {
        Array(viewModel.prioritizedPolicies.dropFirst().prefix(2))
    }
}

private struct HomePolicyDetailRoute: Identifiable {
    let policyID: Int
    let initialTab: PolicyDetailTab

    var id: String {
        "\(policyID)-\(initialTab.rawValue)"
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
