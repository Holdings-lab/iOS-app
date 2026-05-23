import SwiftUI

struct UserSettingsView: View {
    @ObservedObject var notificationCenter: AppNotificationCenter
    @StateObject private var viewModel: UserSettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedThemes: Set<String> = ["반도체", "금리·채권", "환율"]
    @State private var language = "한국어"
    @State private var trustLevel = "보통"
    @State private var themeMode = "시스템"
    @State private var showConfirmationScore = true
    @State private var policyDDayAlert = true
    @State private var analysisDoneAlert = true
    @State private var riskAlert = true
    @State private var proposalAlert = true
    @State private var optimizeData = true

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
        VStack(spacing: 0) {
            navBar

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    if let saveErrorMessage = viewModel.saveErrorMessage {
                        errorBanner(saveErrorMessage)
                    }

                    profileCard
                    portfolioSection
                    signalSection
                    notificationSection
                    appSection
                    accountSection

                    Text("v3.0.1")
                        .font(.pretendard(12, weight: .medium))
                        .foregroundStyle(PSColor.textFaint)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 8)
                }
                .padding(.horizontal, PSSpacing.screenHorizontal)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .background(PSColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .top) {
            if viewModel.isSaving {
                ProgressView()
                    .controlSize(.small)
                    .tint(PSColor.primary)
                    .padding(.top, 6)
            }
        }
        .task {
            await viewModel.loadIfNeeded()
            await notificationCenter.refreshAuthorizationStatus()
        }
    }

    private var navBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(PSColor.textPrimary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("환경설정")
                .font(.pretendard(17, weight: .semibold))
                .foregroundStyle(PSColor.textPrimary)

            Spacer()

            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(PSColor.background)
    }

    private var profileCard: some View {
        PolSignalCard {
            HStack(spacing: 12) {
                Text("투")
                    .font(.pretendard(18, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 48, height: 48)
                    .background(PSColor.primary, in: Circle())

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(viewModel.settings.account.displayName)
                            .font(.pretendard(17, weight: .semibold))
                            .foregroundStyle(PSColor.textPrimary)

                        PolSignalTag(
                            text: "\(viewModel.settings.rebalancing.investmentProfile.displayName) 투자자",
                            style: .primary
                        )
                    }

                    Button("투자 성향 변경 ›") {}
                        .font(.pretendard(13, weight: .regular))
                        .foregroundStyle(PSColor.textSecondary)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var portfolioSection: some View {
        PolSignalSettingSection(title: "내 포트폴리오") {
            NavigationLink {
                PolSignalHoldingsEditorView()
            } label: {
                PolSignalSettingsListRow(
                    title: "보유 자산 편집",
                    subtitle: "ETF·종목 추가, 제거, 비중 조정"
                )
            }
            .buttonStyle(.plain)

            PolSignalSettingsDivider()

            PolSignalSettingsListRow(
                title: "위험 임계값",
                subtitle: "단일 자산 상한 \(viewModel.settings.rebalancing.maxSingleAssetWeight)% 설정 중"
            )

            PolSignalSettingsDivider()

            VStack(alignment: .leading, spacing: 10) {
                Text("관심 테마")
                    .font(.pretendard(13, weight: .semibold))
                    .foregroundStyle(PSColor.textSecondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(["반도체", "금리·채권", "환율", "친환경", "원자재", "부동산·리츠"], id: \.self) { theme in
                        PolSignalCheckChip(title: theme, isOn: selectedThemes.contains(theme)) {
                            if selectedThemes.contains(theme) {
                                selectedThemes.remove(theme)
                            } else {
                                selectedThemes.insert(theme)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private var signalSection: some View {
        PolSignalSettingSection(title: "시그널 설정") {
            PolSignalSettingsListRow(title: "관심 정책 카테고리", subtitle: "산업·금리·환율 우선")
            PolSignalSettingsDivider()
            PolSignalSegmentRow(title: "분석 언어", options: ["한국어", "English"], selection: $language)
            PolSignalSettingsDivider()
            PolSignalSegmentRow(title: "신뢰도 기준", options: ["높음", "보통", "모두"], selection: $trustLevel)
            PolSignalSettingsDivider()
            PolSignalToggleRow(title: "확증 점수 표시", isOn: $showConfirmationScore)
        }
    }

    private var notificationSection: some View {
        PolSignalSettingSection(title: "알림") {
            PolSignalToggleRow(title: "정책 이벤트 D-day 알림", isOn: $policyDDayAlert)
            PolSignalSettingsDivider()
            PolSignalToggleRow(
                title: "시그널 분석 완료 알림",
                subtitle: "이벤트 분석이 완료된 시점에만 발송",
                isOn: $analysisDoneAlert
            )
            PolSignalSettingsDivider()
            PolSignalToggleRow(title: "위험 신호 알림", isOn: $riskAlert)
            PolSignalSettingsDivider()
            PolSignalToggleRow(title: "조정 제안 대기 알림", isOn: $proposalAlert)
            PolSignalSettingsDivider()
            PolSignalSettingsListRow(title: "방해 금지 시간대", subtitle: "별도 설정 화면 예정")
        }
    }

    private var appSection: some View {
        PolSignalSettingSection(title: "앱 설정") {
            PolSignalSegmentRow(title: "테마", options: ["시스템", "라이트", "다크"], selection: $themeMode)
            PolSignalSettingsDivider()
            PolSignalToggleRow(title: "데이터 사용 최적화", isOn: $optimizeData)
        }
    }

    private var accountSection: some View {
        PolSignalSettingSection(title: "계정") {
            PolSignalSettingsListRow(title: "이메일", subtitle: "investor@polsignal.app")
            PolSignalSettingsDivider()
            PolSignalSettingsListRow(title: "비밀번호 변경")
            PolSignalSettingsDivider()
            PolSignalSettingsListRow(title: "로그아웃")
            PolSignalSettingsDivider()
            PolSignalSettingsListRow(title: "회원 탈퇴", tone: .danger)
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
        .foregroundStyle(PSColor.danger)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PSColor.dangerBg, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
