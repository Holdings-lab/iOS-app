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
            PolSignalToggleRow(title: "시그널 분석 완료 알림", isOn: $analysisDoneAlert)
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

private struct PolSignalSettingSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.pretendard(13, weight: .semibold))
                .foregroundStyle(PSColor.textSecondary)

            VStack(spacing: 0) {
                content
            }
            .background(PSColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(PSColor.border, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

private struct PolSignalSettingsListRow: View {
    enum Tone {
        case normal
        case danger
    }

    let title: String
    var subtitle: String?
    var tone: Tone = .normal

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(tone == .danger ? PSColor.danger : PSColor.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.pretendard(12, weight: .regular))
                        .foregroundStyle(PSColor.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 12)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(PSColor.textFaint)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }
}

private struct PolSignalToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.pretendard(14, weight: .semibold))
                .foregroundStyle(PSColor.textPrimary)

            Spacer()

            PolSignalToggle(isOn: $isOn)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(minHeight: 52)
    }
}

private struct PolSignalToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                isOn.toggle()
            }
        } label: {
            Capsule(style: .continuous)
                .fill(isOn ? PSColor.primary : PSColor.border)
                .frame(width: 44, height: 26)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                        .padding(2)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOn ? "켬" : "끔")
    }
}

private struct PolSignalSegmentRow: View {
    let title: String
    let options: [String]
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.pretendard(14, weight: .semibold))
                .foregroundStyle(PSColor.textPrimary)

            Spacer()

            HStack(spacing: 3) {
                ForEach(options, id: \.self) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selection = option
                        }
                    } label: {
                        Text(option)
                            .font(.pretendard(12, weight: .semibold))
                            .foregroundStyle(selection == option ? PSColor.textPrimary : PSColor.textSecondary)
                            .padding(.horizontal, 9)
                            .frame(height: 28)
                            .background(selection == option ? PSColor.surface : Color.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .shadow(color: selection == option ? PSColor.cardShadow : Color.clear, radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(Color(hex: "F1F5F9"), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(minHeight: 52)
    }
}

private struct PolSignalCheckChip: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.pretendard(13, weight: .semibold))
                .foregroundStyle(isOn ? PSColor.primary : PSColor.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(isOn ? PSColor.primarySoft : PSColor.surfaceAlt, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isOn ? PSColor.primary : PSColor.rule, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

private struct PolSignalSettingsDivider: View {
    var body: some View {
        Divider()
            .background(PSColor.rule)
            .padding(.leading, 20)
    }
}

private struct PolSignalHoldingsEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var holdings: [EditableHolding] = [
        EditableHolding(ticker: "SOXX", name: "iShares Semiconductor ETF", percent: 12, color: PSColor.primary),
        EditableHolding(ticker: "SMH", name: "VanEck Semiconductor ETF", percent: 8, color: PSColor.tagSemi),
        EditableHolding(ticker: "QQQ", name: "Invesco QQQ Trust", percent: 9, color: PSColor.success)
    ]

    private let suggestions = ["SMH", "QQQ", "TLT", "GLD", "SCHD"]

    var body: some View {
        VStack(spacing: 0) {
            holdingsNavBar

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    searchBar
                    holdingsSection
                    totalCard
                    addAssetButton
                    suggestionsSection
                }
                .padding(.horizontal, PSSpacing.screenHorizontal)
                .padding(.top, 10)
                .padding(.bottom, 32)
            }
        }
        .background(PSColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var holdingsNavBar: some View {
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

            Text("보유 자산")
                .font(.pretendard(17, weight: .semibold))
                .foregroundStyle(PSColor.textPrimary)

            Spacer()

            Button("완료") {
                dismiss()
            }
            .font(.pretendard(15, weight: .semibold))
            .foregroundStyle(PSColor.primary)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(PSColor.background)
    }

    private var searchBar: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(PSColor.textFaint)

            TextField("ETF, 종목명 검색", text: $searchText)
                .font(.pretendard(14, weight: .regular))
                .foregroundStyle(PSColor.textPrimary)
                .textInputAutocapitalization(.characters)
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(PSColor.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(PSColor.border, lineWidth: 1)
        }
    }

    private var holdingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            PolSignalSectionHeader(title: "보유 중", meta: "\(holdings.count)개")

            PolSignalCard(padding: EdgeInsets(top: 4, leading: 14, bottom: 4, trailing: 14)) {
                VStack(spacing: 0) {
                    ForEach($holdings) { $holding in
                        HoldingRow(
                            holding: $holding,
                            onRemove: {
                                holdings.removeAll { $0.id == holding.id }
                            }
                        )

                        if holding.id != holdings.last?.id {
                            Divider().background(PSColor.rule)
                        }
                    }
                }
            }
        }
    }

    private var totalCard: some View {
        PolSignalCard(padding: EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("합계")
                        .font(.pretendard(13, weight: .regular))
                        .foregroundStyle(PSColor.textSecondary)
                    Spacer()
                    Text("\(Int(totalPercent))%")
                        .font(.pretendard(14, weight: .semibold))
                        .foregroundStyle(totalPercent > 100 ? PSColor.danger : PSColor.textPrimary)
                    Text("/ 100%")
                        .font(.pretendard(13, weight: .regular))
                        .foregroundStyle(PSColor.textFaint)
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(PSColor.rule)
                        Capsule()
                            .fill(totalPercent > 100 ? PSColor.danger : PSColor.primary)
                            .frame(width: min(proxy.size.width, proxy.size.width * totalPercent / 100))
                    }
                }
                .frame(height: 10)

                Text("나머지 \(max(0, Int(100 - totalPercent)))%는 기타로 분류됩니다")
                    .font(.pretendard(12, weight: .regular))
                    .foregroundStyle(PSColor.textFaint)
            }
        }
    }

    private var addAssetButton: some View {
        Button {} label: {
            Text("+ 자산 추가")
                .font(.pretendard(14, weight: .semibold))
                .foregroundStyle(PSColor.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(PSColor.primarySoft.opacity(0.35), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(PSColor.border, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                }
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("자주 추가되는 자산")
                .font(.pretendard(13, weight: .regular))
                .foregroundStyle(PSColor.textSecondary)

            PolSignalFlowLayout(spacing: 8) {
                ForEach(suggestions, id: \.self) { ticker in
                    Button {
                        addQuick(ticker)
                    } label: {
                        Text(ticker)
                            .font(.pretendard(13, weight: .semibold))
                            .foregroundStyle(PSColor.primary)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 8)
                            .background(PSColor.surface, in: Capsule(style: .continuous))
                            .overlay {
                                Capsule(style: .continuous)
                                    .stroke(PSColor.primary.opacity(0.35), lineWidth: 1.5)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var totalPercent: Double {
        holdings.reduce(0) { $0 + $1.percent }
    }

    private func addQuick(_ ticker: String) {
        guard holdings.contains(where: { $0.ticker == ticker }) == false else { return }
        holdings.append(
            EditableHolding(
                ticker: ticker,
                name: quickName(for: ticker),
                percent: 0,
                color: PSColor.primary
            )
        )
    }

    private func quickName(for ticker: String) -> String {
        switch ticker {
        case "TLT":
            return "iShares 20+ Year Treasury Bond"
        case "GLD":
            return "SPDR Gold Shares"
        case "SCHD":
            return "Schwab U.S. Dividend Equity"
        case "SMH":
            return "VanEck Semiconductor ETF"
        case "QQQ":
            return "Invesco QQQ Trust"
        default:
            return "\(ticker) ETF"
        }
    }
}

private struct EditableHolding: Identifiable {
    let id = UUID()
    var ticker: String
    var name: String
    var percent: Double
    var color: Color
}

private struct HoldingRow: View {
    @Binding var holding: EditableHolding
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(String(holding.ticker.prefix(4)))
                .font(.pretendard(11, weight: .bold))
                .foregroundStyle(holding.color)
                .frame(width: 38, height: 38)
                .background(holding.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(holding.ticker)
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(PSColor.textPrimary)
                Text(holding.name)
                    .font(.pretendard(12, weight: .regular))
                    .foregroundStyle(PSColor.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            HStack(spacing: 2) {
                TextField("", value: $holding.percent, format: .number.precision(.fractionLength(0)))
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(PSColor.textPrimary)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                    .frame(width: 34)
                Text("%")
                    .font(.pretendard(13, weight: .semibold))
                    .foregroundStyle(PSColor.textSecondary)
            }

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(PSColor.textFaint)
                    .frame(width: 26, height: 26)
                    .background(PSColor.surfaceAlt, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 11)
    }
}
