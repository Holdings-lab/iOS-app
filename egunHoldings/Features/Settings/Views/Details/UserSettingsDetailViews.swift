import SwiftUI

struct AccountSettingsDetailView: View {
    @ObservedObject var viewModel: UserSettingsViewModel

    var body: some View {
        SettingsDetailContainer(title: "계정 정보") {
            SettingsSection(title: "기본 정보") {
                SettingsInfoRow(title: "이름", value: viewModel.settings.account.displayName)
                SettingsDivider()
                SettingsInfoRow(title: "로그인 계정", value: viewModel.settings.account.loginAccount)
                SettingsDivider()
                SettingsInfoRow(title: "로그인 방식", value: viewModel.settings.account.authProvider)
                SettingsDivider()
                SettingsInfoRow(title: "가입일", value: viewModel.settings.account.memberSince)
            }

            SettingsSection(title: "계정 관리") {
                SettingsRowContent(
                    iconName: "rectangle.portrait.and.arrow.right",
                    title: "로그아웃",
                    value: "",
                    color: Color.textTertiary,
                    showsChevron: false
                )
                SettingsDivider()
                SettingsRowContent(
                    iconName: "trash.fill",
                    title: "회원 탈퇴",
                    value: "",
                    color: Color.up,
                    showsChevron: false
                )
            }
        }
    }
}

struct RebalancingSettingsDetailView: View {
    @ObservedObject var viewModel: UserSettingsViewModel

    var body: some View {
        SettingsDetailContainer(title: "투자 성향") {
            SettingsSection(title: "투자 성향") {
                ForEach(InvestmentProfile.allCases) { profile in
                    SettingsOptionButton(
                        title: profile.displayName,
                        subtitle: profileSubtitle(profile),
                        isSelected: viewModel.settings.rebalancing.investmentProfile == profile
                    ) {
                        Task {
                            await viewModel.updateInvestmentProfile(profile)
                        }
                    }
                    if profile != InvestmentProfile.allCases.last! {
                        SettingsDivider()
                    }
                }
            }

            SettingsSection(title: AppVocabulary.Rebalancing.appliedCriteria) {
                SettingsStepperRow(
                    title: AppVocabulary.Rebalancing.targetCashWeight,
                    valueText: "\(viewModel.settings.rebalancing.targetCashWeight)%",
                    decrement: {
                        Task {
                            await viewModel.updateTargetCashWeight(viewModel.settings.rebalancing.targetCashWeight - 5)
                        }
                    },
                    increment: {
                        Task {
                            await viewModel.updateTargetCashWeight(viewModel.settings.rebalancing.targetCashWeight + 5)
                        }
                    }
                )
                SettingsDivider()
                SettingsStepperRow(
                    title: AppVocabulary.Rebalancing.rebalanceThreshold,
                    valueText: "\(viewModel.settings.rebalancing.rebalanceThreshold)%",
                    decrement: {
                        Task {
                            await viewModel.updateRebalanceThreshold(viewModel.settings.rebalancing.rebalanceThreshold - 1)
                        }
                    },
                    increment: {
                        Task {
                            await viewModel.updateRebalanceThreshold(viewModel.settings.rebalancing.rebalanceThreshold + 1)
                        }
                    }
                )
                SettingsDivider()
                SettingsStepperRow(
                    title: AppVocabulary.Rebalancing.maxSingleAssetWeight,
                    valueText: "\(viewModel.settings.rebalancing.maxSingleAssetWeight)%",
                    decrement: {
                        Task {
                            await viewModel.updateMaxSingleAssetWeight(viewModel.settings.rebalancing.maxSingleAssetWeight - 5)
                        }
                    },
                    increment: {
                        Task {
                            await viewModel.updateMaxSingleAssetWeight(viewModel.settings.rebalancing.maxSingleAssetWeight + 5)
                        }
                    }
                )
                SettingsDivider()
                SettingsInfoRow(
                    title: AppVocabulary.Rebalancing.minTradeAmount,
                    value: "\(viewModel.settings.rebalancing.minTradeAmount.formattedKRW)원"
                )
            }
        }
    }

    private func profileSubtitle(_ profile: InvestmentProfile) -> String {
        switch profile {
        case .conservative:
            return "방어적 현금 비중과 낮은 한 자산 최대 비중"
        case .balanced:
            return "현금 방어와 성장 노출을 균형 있게 반영"
        case .aggressive:
            return "높은 성장 노출과 빠른 리밸런싱 반응"
        }
    }
}

struct PushPermissionSettingsDetailView: View {
    @ObservedObject var notificationCenter: AppNotificationCenter

    var body: some View {
        SettingsDetailContainer(title: "푸시 알림 권한") {
            SettingsSection(title: "상태") {
                SettingsInfoRow(title: "iOS 권한", value: notificationCenter.authorizationStatusText)
                SettingsDivider()
                Button {
                    Task {
                        await notificationCenter.requestAuthorization()
                    }
                } label: {
                    Text("권한 요청")
                        .font(.pretendard(14, weight: .bold))
                        .foregroundStyle(Color.brand)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(PSPressStyle())
            }

            SettingsSection(title: "사용 목적") {
                SettingsInfoRow(title: "정책", value: "내 자산 영향권 정책 발생")
                SettingsDivider()
                SettingsInfoRow(title: "기사", value: "보유 자산 관련 중요 기사")
                SettingsDivider()
                SettingsInfoRow(title: "위험", value: "변동성 확대와 급락 위험")
            }
        }
    }
}

struct DevicePushRegistrationDetailView: View {
    @ObservedObject var notificationCenter: AppNotificationCenter

    var body: some View {
        SettingsDetailContainer(title: "알림 수신 기기") {
            SettingsSection(title: "등록 상태") {
                SettingsInfoRow(title: "상태", value: notificationCenter.remoteRegistrationStatusText)
                SettingsDivider()
                SettingsInfoRow(title: "토큰", value: tokenText)
                if let error = notificationCenter.remoteRegistrationError {
                    SettingsDivider()
                    SettingsInfoRow(title: "오류", value: error)
                }
            }

            SettingsSection(title: "재등록") {
                Button {
                    Task {
                        await notificationCenter.requestAuthorization()
                    }
                } label: {
                    Text("푸시 등록 다시 시도")
                        .font(.pretendard(14, weight: .bold))
                        .foregroundStyle(Color.brand)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(PSPressStyle())
            }
        }
    }

    private var tokenText: String {
        guard let token = notificationCenter.deviceToken, token.isEmpty == false else {
            return "없음"
        }

        return "\(token.prefix(8))...\(token.suffix(8))"
    }
}

struct PolicyNotificationSettingsDetailView: View {
    @ObservedObject var viewModel: UserSettingsViewModel

    var body: some View {
        SettingsDetailContainer(title: "정책 업데이트") {
            SettingsSection(title: "알림") {
                SettingsToggleRow(
                    iconName: "building.columns.fill",
                    title: "정책 업데이트 받기",
                    value: Binding(
                        get: { viewModel.settings.notifications.policyPushEnabled },
                        set: { value in
                            Task { await viewModel.updatePolicyPushEnabled(value) }
                        }
                    ),
                    color: Color.brand
                )
            }

            SettingsSection(title: "기준") {
                SettingsStepperRow(
                    title: "내 자산 영향도",
                    valueText: "\(viewModel.settings.notifications.policyImpactThreshold)% 이상",
                    decrement: {
                        Task {
                            await viewModel.updateNotificationPolicyImpactThreshold(
                                viewModel.settings.notifications.policyImpactThreshold - 5
                            )
                        }
                    },
                    increment: {
                        Task {
                            await viewModel.updateNotificationPolicyImpactThreshold(
                                viewModel.settings.notifications.policyImpactThreshold + 5
                            )
                        }
                    }
                )
                SettingsDivider()
                SettingsInfoRow(
                    title: "관심 카테고리",
                    value: viewModel.settings.notifications.policyCategories.joined(separator: ", ")
                )
            }
        }
    }
}

struct NewsNotificationSettingsDetailView: View {
    @ObservedObject var viewModel: UserSettingsViewModel

    var body: some View {
        SettingsDetailContainer(title: "기사 업데이트") {
            SettingsSection(title: "알림") {
                SettingsToggleRow(
                    iconName: "newspaper.fill",
                    title: "기사 업데이트 받기",
                    value: Binding(
                        get: { viewModel.settings.notifications.newsPushEnabled },
                        set: { value in
                            Task { await viewModel.updateNewsPushEnabled(value) }
                        }
                    ),
                    color: Color.brandLight
                )
                SettingsDivider()
                SettingsToggleRow(
                    iconName: "line.3.horizontal.decrease.circle.fill",
                    title: "중요 기사만 받기",
                    value: Binding(
                        get: { viewModel.settings.notifications.highRelevanceNewsOnly },
                        set: { value in
                            Task { await viewModel.updateHighRelevanceNewsOnly(value) }
                        }
                    ),
                    color: Color.brand
                )
            }

            SettingsSection(title: "전달 방식") {
                ForEach(SettingsNewsDigestMode.allCases) { mode in
                    SettingsOptionButton(
                        title: mode.title,
                        isSelected: viewModel.settings.notifications.newsDigestMode == mode
                    ) {
                        Task {
                            await viewModel.updateNewsDigestMode(mode)
                        }
                    }
                    if mode != SettingsNewsDigestMode.allCases.last! {
                        SettingsDivider()
                    }
                }
            }
        }
    }
}

struct VolatilityNotificationSettingsDetailView: View {
    @ObservedObject var viewModel: UserSettingsViewModel

    var body: some View {
        SettingsDetailContainer(title: "자산 변동성 위험") {
            SettingsSection(title: "알림") {
                SettingsToggleRow(
                    iconName: "exclamationmark.triangle.fill",
                    title: "변동성 위험 받기",
                    value: Binding(
                        get: { viewModel.settings.notifications.volatilityPushEnabled },
                        set: { value in
                            Task { await viewModel.updateVolatilityPushEnabled(value) }
                        }
                    ),
                    color: Color.up
                )
            }

            SettingsSection(title: "민감도") {
                ForEach(SettingsVolatilityLevel.allCases) { level in
                    SettingsOptionButton(
                        title: level.title,
                        subtitle: level.summary,
                        isSelected: viewModel.settings.notifications.volatilityLevel == level
                    ) {
                        Task {
                            await viewModel.updateNotificationVolatilityLevel(level)
                        }
                    }
                    if level != SettingsVolatilityLevel.allCases.last! {
                        SettingsDivider()
                    }
                }
            }
        }
    }
}

struct QuietHoursSettingsDetailView: View {
    @ObservedObject var viewModel: UserSettingsViewModel

    var body: some View {
        SettingsDetailContainer(title: "야간 알림") {
            SettingsSection(title: "방해 금지") {
                SettingsToggleRow(
                    iconName: "moon.fill",
                    title: "야간 알림 줄이기",
                    value: Binding(
                        get: { viewModel.settings.notifications.quietHoursEnabled },
                        set: { value in
                            Task { await viewModel.updateQuietHoursEnabled(value) }
                        }
                    ),
                    color: Color.textTertiary
                )
                SettingsDivider()
                SettingsInfoRow(title: "시작", value: viewModel.settings.notifications.quietHoursStart)
                SettingsDivider()
                SettingsInfoRow(title: "종료", value: viewModel.settings.notifications.quietHoursEnd)
            }

            SettingsSection(title: "예외") {
                SettingsInfoRow(title: "긴급 위험", value: "자산 급락 위험은 즉시 알림")
                SettingsDivider()
                SettingsInfoRow(title: "일반 기사", value: "다음 날 요약으로 이동")
            }
        }
    }
}

struct BrokerConnectionSettingsDetailView: View {
    @ObservedObject var viewModel: UserSettingsViewModel

    var body: some View {
        SettingsDetailContainer(title: "증권사 연결") {
            SettingsSection(title: "연결 정보") {
                SettingsInfoRow(title: "증권사", value: viewModel.settings.portfolio.connectedBrokerText)
                SettingsDivider()
                SettingsInfoRow(title: "권한", value: viewModel.settings.portfolio.brokerPermissionText)
                SettingsDivider()
                SettingsInfoRow(title: "마지막 동기화", value: viewModel.settings.portfolio.lastSyncedAt)
            }

            SettingsSection(title: "관리") {
                SettingsRowContent(
                    iconName: "arrow.clockwise.circle.fill",
                    title: "잔고 다시 동기화",
                    value: "",
                    color: Color.brand,
                    showsChevron: false
                )
                SettingsDivider()
                SettingsRowContent(
                    iconName: "xmark.circle.fill",
                    title: "연결 해제",
                    value: "",
                    color: Color.up,
                    showsChevron: false
                )
            }
        }
    }
}

struct AssetVolatilityCriteriaSettingsDetailView: View {
    @ObservedObject var viewModel: UserSettingsViewModel

    var body: some View {
        SettingsDetailContainer(title: "자산 변동성 기준") {
            SettingsSection(title: "기준") {
                ForEach(SettingsVolatilityLevel.allCases) { level in
                    SettingsOptionButton(
                        title: level.title,
                        subtitle: level.summary,
                        isSelected: viewModel.settings.portfolio.volatilityLevel == level
                    ) {
                        Task {
                            await viewModel.updatePortfolioVolatilityLevel(level)
                        }
                    }
                    if level != SettingsVolatilityLevel.allCases.last! {
                        SettingsDivider()
                    }
                }
            }
        }
    }
}

struct PolicyImpactCriteriaSettingsDetailView: View {
    @ObservedObject var viewModel: UserSettingsViewModel

    var body: some View {
        SettingsDetailContainer(title: "정책 영향도 기준") {
            SettingsSection(title: "노출도 기준") {
                SettingsStepperRow(
                    title: "내 자산 관련도",
                    valueText: "\(viewModel.settings.portfolio.policyImpactThreshold)% 이상",
                    decrement: {
                        Task {
                            await viewModel.updatePortfolioPolicyImpactThreshold(
                                viewModel.settings.portfolio.policyImpactThreshold - 5
                            )
                        }
                    },
                    increment: {
                        Task {
                            await viewModel.updatePortfolioPolicyImpactThreshold(
                                viewModel.settings.portfolio.policyImpactThreshold + 5
                            )
                        }
                    }
                )
            }

            SettingsSection(title: "설명") {
                SettingsInfoRow(title: "홈 정책 카드", value: "이 기준 이상인 정책 우선 노출")
                SettingsDivider()
                SettingsInfoRow(title: "알림", value: "알림 기준과 별도로 조정 가능")
            }
        }
    }
}

struct DataSyncSettingsDetailView: View {
    @ObservedObject var viewModel: UserSettingsViewModel

    var body: some View {
        SettingsDetailContainer(title: "데이터 동기화") {
            SettingsSection(title: "동기화 방식") {
                ForEach(SettingsDataSyncMode.allCases) { mode in
                    SettingsOptionButton(
                        title: mode.title,
                        subtitle: mode == .automatic ? "앱 실행과 새로고침 시 서버 동기화" : "사용자가 요청할 때만 동기화",
                        isSelected: viewModel.settings.data.syncMode == mode
                    ) {
                        Task {
                            await viewModel.updateDataSyncMode(mode)
                        }
                    }
                    if mode != SettingsDataSyncMode.allCases.last! {
                        SettingsDivider()
                    }
                }
            }

            SettingsSection(title: "상태") {
                SettingsInfoRow(title: "주기", value: viewModel.settings.data.syncIntervalText)
                SettingsDivider()
                SettingsInfoRow(title: "대상", value: "정책, 기사, 자산 스냅샷")
            }
        }
    }
}

struct ContentSourcesSettingsDetailView: View {
    @ObservedObject var viewModel: UserSettingsViewModel

    var body: some View {
        SettingsDetailContainer(title: "정책/기사 출처") {
            SettingsSection(title: "사용 중인 출처") {
                ForEach(Array(viewModel.settings.data.sources.enumerated()), id: \.offset) { index, source in
                    SettingsInfoRow(title: source, value: "활성")
                    if index < viewModel.settings.data.sources.count - 1 {
                        SettingsDivider()
                    }
                }
            }

            SettingsSection(title: "검증 기준") {
                SettingsInfoRow(title: "정책", value: "기관 발표와 공신력 있는 보도")
                SettingsDivider()
                SettingsInfoRow(title: "기사", value: "보유 자산 관련도 기준 필터링")
            }
        }
    }
}

struct PrivacySecuritySettingsDetailView: View {
    @ObservedObject var viewModel: UserSettingsViewModel

    var body: some View {
        SettingsDetailContainer(title: "개인정보 및 보안") {
            SettingsSection(title: "데이터 사용") {
                ForEach(Array(viewModel.settings.guide.privacyItems.enumerated()), id: \.offset) { index, item in
                    SettingsInfoRow(title: "항목 \(index + 1)", value: item)
                    if index < viewModel.settings.guide.privacyItems.count - 1 {
                        SettingsDivider()
                    }
                }
            }
        }
    }
}

struct InvestmentDisclaimerSettingsDetailView: View {
    @ObservedObject var viewModel: UserSettingsViewModel

    var body: some View {
        SettingsDetailContainer(title: "투자 추천 아님") {
            SettingsSection(title: "안내") {
                ForEach(Array(viewModel.settings.guide.disclaimerItems.enumerated()), id: \.offset) { index, item in
                    SettingsInfoRow(title: "안내 \(index + 1)", value: item)
                    if index < viewModel.settings.guide.disclaimerItems.count - 1 {
                        SettingsDivider()
                    }
                }
            }
        }
    }
}

private extension Int {
    var formattedKRW: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
