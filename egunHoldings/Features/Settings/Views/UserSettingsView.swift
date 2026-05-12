import SwiftUI

struct UserSettingsView: View {
    @ObservedObject var notificationCenter: AppNotificationCenter
    @StateObject private var viewModel: UserSettingsViewModel

    init(
        userId: Int64?,
        notificationCenter: AppNotificationCenter,
        connectedBrokerText: String,
        viewModel: UserSettingsViewModel? = nil
    ) {
        self.notificationCenter = notificationCenter
        _viewModel = StateObject(
            wrappedValue: viewModel ?? UserSettingsViewModel(
                userId: userId,
                connectedBrokerText: connectedBrokerText
            )
        )
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                if let saveErrorMessage = viewModel.saveErrorMessage {
                    errorBanner(saveErrorMessage)
                }

                profileSection
                notificationSection
                portfolioSection
                dataSection
                guideSection
            }
            .padding(.horizontal, KDXSpacing.screenHorizontal)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Color.canvas.ignoresSafeArea())
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .overlay(alignment: .top) {
            if viewModel.isSaving {
                ProgressView()
                    .controlSize(.small)
                    .tint(Color.brand)
                    .padding(.top, 6)
            }
        }
        .task {
            await viewModel.loadIfNeeded()
            await notificationCenter.refreshAuthorizationStatus()
        }
    }

    private var profileSection: some View {
        SettingsSection(title: "사용자") {
            SettingsNavigationLink(
                iconName: "person.circle.fill",
                title: "계정 정보",
                value: viewModel.settings.account.displayName
            ) {
                AccountSettingsDetailView(viewModel: viewModel)
            }
            SettingsDivider()
            SettingsNavigationLink(
                iconName: "slider.horizontal.3",
                title: "투자 성향과 리밸런싱 기준",
                value: viewModel.settings.rebalancing.investmentProfile.displayName
            ) {
                RebalancingSettingsDetailView(viewModel: viewModel)
            }
        }
    }

    private var notificationSection: some View {
        SettingsSection(title: "알림") {
            SettingsNavigationLink(
                iconName: "bell.badge.fill",
                title: "푸시 알림 권한",
                value: notificationCenter.authorizationStatusText
            ) {
                PushPermissionSettingsDetailView(notificationCenter: notificationCenter)
            }
            SettingsDivider()
            SettingsNavigationLink(
                iconName: "iphone.radiowaves.left.and.right",
                title: "디바이스 푸시 등록",
                value: notificationCenter.remoteRegistrationStatusText
            ) {
                DevicePushRegistrationDetailView(notificationCenter: notificationCenter)
            }
            SettingsDivider()
            SettingsNavigationLink(
                iconName: "building.columns.fill",
                title: "정책 업데이트",
                value: viewModel.policyPushStatusText
            ) {
                PolicyNotificationSettingsDetailView(viewModel: viewModel)
            }
            SettingsDivider()
            SettingsNavigationLink(
                iconName: "newspaper.fill",
                title: "기사 업데이트",
                value: viewModel.newsPushStatusText,
                color: Color.brandLight
            ) {
                NewsNotificationSettingsDetailView(viewModel: viewModel)
            }
            SettingsDivider()
            SettingsNavigationLink(
                iconName: "exclamationmark.triangle.fill",
                title: "자산 변동성 위험",
                value: viewModel.volatilityPushStatusText,
                color: Color.up
            ) {
                VolatilityNotificationSettingsDetailView(viewModel: viewModel)
            }
            SettingsDivider()
            SettingsNavigationLink(
                iconName: "moon.fill",
                title: "야간 알림 줄이기",
                value: viewModel.quietHoursStatusText,
                color: Color.textTertiary
            ) {
                QuietHoursSettingsDetailView(viewModel: viewModel)
            }
            SettingsDivider()
            Button {
                Task {
                    await notificationCenter.scheduleTestNotification()
                }
            } label: {
                HStack {
                    Text("테스트 알림 보내기")
                        .font(.pretendard(14, weight: .semibold))
                    Spacer()
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color.brand)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(PSPressStyle())
        }
    }

    private var portfolioSection: some View {
        SettingsSection(title: "자산") {
            SettingsNavigationLink(
                iconName: "building.2.fill",
                title: "증권사 연결 관리",
                value: viewModel.settings.portfolio.connectedBrokerText
            ) {
                BrokerConnectionSettingsDetailView(viewModel: viewModel)
            }
            SettingsDivider()
            SettingsNavigationLink(
                iconName: "chart.pie.fill",
                title: "자산 변동성 기준",
                value: viewModel.settings.portfolio.volatilityLevel.title
            ) {
                AssetVolatilityCriteriaSettingsDetailView(viewModel: viewModel)
            }
            SettingsDivider()
            SettingsNavigationLink(
                iconName: "percent",
                title: "정책 영향도 기준",
                value: viewModel.policyImpactThresholdText
            ) {
                PolicyImpactCriteriaSettingsDetailView(viewModel: viewModel)
            }
        }
    }

    private var dataSection: some View {
        SettingsSection(title: "데이터") {
            SettingsNavigationLink(
                iconName: "arrow.clockwise.circle.fill",
                title: "데이터 동기화",
                value: viewModel.settings.data.syncMode.title
            ) {
                DataSyncSettingsDetailView(viewModel: viewModel)
            }
            SettingsDivider()
            SettingsNavigationLink(
                iconName: "doc.text.magnifyingglass",
                title: "정책/기사 출처",
                value: "확인"
            ) {
                ContentSourcesSettingsDetailView(viewModel: viewModel)
            }
        }
    }

    private var guideSection: some View {
        SettingsSection(title: "안내") {
            SettingsNavigationLink(
                iconName: "shield.lefthalf.filled",
                title: "개인정보 및 보안"
            ) {
                PrivacySecuritySettingsDetailView(viewModel: viewModel)
            }
            SettingsDivider()
            SettingsNavigationLink(
                iconName: "info.circle.fill",
                title: "투자 권유 아님 안내"
            ) {
                InvestmentDisclaimerSettingsDetailView(viewModel: viewModel)
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 13, weight: .semibold))
            Text(message)
                .font(.pretendard(12, weight: .medium))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(Color.up)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.upBg, in: RoundedRectangle(cornerRadius: KDXRadius.button, style: .continuous))
    }
}
