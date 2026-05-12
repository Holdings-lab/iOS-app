import SwiftUI

struct PolicyNewsInsightDetailView: View {
    let item: PolicyNewsItem
    let userAssetProfile: UserAssetProfile
    @ObservedObject var viewModel: PolicyNewsViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private var mode: NewsroomInsightMode {
        viewModel.presentedInsightMode
    }

    private var modeTint: Color {
        mode == .quick ? Color.electricBlue : item.newsroomAccentColor
    }

    var body: some View {
        ZStack {
            Color.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView(.vertical, showsIndicators: false) {
                    content
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomActionBar
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var topBar: some View {
        HStack {
            Button {
                close()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                    Text("이전")
                        .font(.pretendard(14, weight: .bold))
                }
                .foregroundStyle(Color.textSecondary)
                .frame(height: 40)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(mode.title)
                .font(.pretendard(13, weight: .bold))
                .foregroundStyle(modeTint)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(modeTint.opacity(0.10), in: Capsule(style: .continuous))
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .background(Color.canvas.opacity(0.96))
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            summaryHeader

            if let insight = viewModel.presentedInsight {
                loadedContent(insight)
            } else if viewModel.isInsightLoading {
                loadingState
            } else if let errorMessage = viewModel.insightErrorMessage {
                errorState(message: errorMessage)
            } else {
                loadingState
            }
        }
    }

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 8) {
                Text(item.category.title)
                    .font(.pretendard(11, weight: .bold))
                    .foregroundStyle(item.newsroomAccentColor)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(item.newsroomAccentColor.opacity(0.12), in: Capsule(style: .continuous))

                Text(item.newsroomSourceTimeText)
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)

                Spacer()
            }

            Text(item.title)
                .font(.pretendard(24, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(item.summary)
                .font(.pretendard(14, weight: .medium))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    @ViewBuilder
    private func loadedContent(_ insight: PolicyNewsInsight) -> some View {
        switch mode {
        case .quick:
            quickContent(insight)
        case .detail:
            detailContent(insight)
        }
    }

    private func quickContent(_ insight: PolicyNewsInsight) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            decisionCard

            InsightVisualCard(
                title: "왜 중요한가",
                subtitle: "3줄 판단 근거",
                iconName: "bolt.fill",
                tint: Color.electricBlue,
                rows: Array(insight.articleSummary.prefix(3)),
                style: .numbered
            )

            quickPortfolioCard(insight)

            InsightVisualCard(
                title: "오늘 확인할 것",
                subtitle: "행동 전 체크",
                iconName: "checklist",
                tint: Color.policyAmber,
                rows: quickChecklist(from: insight),
                style: .check
            )

            NewsInvestmentDisclaimer()
                .padding(.top, 2)
        }
    }

    private func detailContent(_ insight: PolicyNewsInsight) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            InsightVisualCard(
                title: "정책/기사 배경",
                subtitle: "왜 나온 이슈인지",
                iconName: "newspaper.fill",
                tint: Color.electricBlue,
                rows: insight.articleSummary,
                style: .numbered
            )

            portfolioImpactCard(insight)

            scenarioComparisonCard

            InsightVisualCard(
                title: "확인할 숫자와 날짜",
                subtitle: "판단 기준",
                iconName: "checklist",
                tint: Color.policyAmber,
                rows: insight.actionChecklist.isEmpty ? [item.newsroomCheckConditionText] : insight.actionChecklist,
                style: .check
            )

            InsightVisualCard(
                title: "과잉 해석 주의",
                subtitle: "반대로 볼 지점",
                iconName: "exclamationmark.triangle.fill",
                tint: Color.textTertiary,
                rows: riskRows(from: insight),
                style: .dot
            )

            relatedHoldingsCard

            sourceInfoCard(insight)

            NewsInvestmentDisclaimer()
                .padding(.top, 2)
        }
    }

    private var decisionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            InsightSectionHeader(
                title: "지금 판단",
                subtitle: "빠른 의사결정",
                iconName: decisionIconName,
                tint: decisionTint
            )

            Text(decisionTitle)
                .font(.pretendard(22, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(decisionDescription)
                .font(.pretendard(13, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                quickBadge("원문 확인")
                quickBadge(item.newsroomRelevanceLevel == .high ? "내 자산 관련" : "시장 맥락")
                quickBadge(item.sentiment == .caution ? "변동성 주의" : "분할 접근")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(decisionTint.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(decisionTint.opacity(0.16), lineWidth: 1)
        }
    }

    private func quickPortfolioCard(_ insight: PolicyNewsInsight) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            InsightSectionHeader(
                title: "내 자산 영향",
                subtitle: "핵심만 보기",
                iconName: "chart.pie.fill",
                tint: Color.emerald
            )

            InsightRow(
                index: 1,
                text: insight.portfolioHeadline,
                tint: Color.emerald,
                style: .numbered
            )

            ForEach(Array(insight.portfolioBullets.prefix(1).enumerated()), id: \.offset) { index, bullet in
                InsightRow(
                    index: index + 2,
                    text: bullet,
                    tint: Color.emerald,
                    style: .numbered
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private func portfolioImpactCard(_ insight: PolicyNewsInsight) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            InsightSectionHeader(
                title: "내 자산 기준",
                subtitle: "보유자산 영향",
                iconName: "chart.pie.fill",
                tint: Color.emerald
            )

            Text(insight.portfolioHeadline)
                .font(.pretendard(15, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                alignment: .leading,
                spacing: 8
            ) {
                ForEach(Array(insight.portfolioBullets.enumerated()), id: \.offset) { index, bullet in
                    MiniInsightTile(
                        index: index + 1,
                        text: bullet,
                        tint: Color.emerald
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private var relatedHoldingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            InsightSectionHeader(
                title: "관련 보유자산",
                subtitle: "\(item.newsroomAssetTags.count)개 연결",
                iconName: "tag.fill",
                tint: item.newsroomAccentColor
            )

            NewsAssetTagFlow(tags: item.newsroomAssetTags)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private var scenarioComparisonCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            InsightSectionHeader(
                title: "긍정/부정 시나리오",
                subtitle: "어느 쪽으로 확인할지",
                iconName: "arrow.left.arrow.right",
                tint: item.newsroomAccentColor
            )

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                alignment: .leading,
                spacing: 8
            ) {
                ScenarioTile(
                    title: "긍정",
                    text: positiveScenarioText,
                    tint: Color.emerald
                )

                ScenarioTile(
                    title: "부정",
                    text: negativeScenarioText,
                    tint: Color.policyCoral
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private func sourceInfoCard(_ insight: PolicyNewsInsight) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            InsightSectionHeader(
                title: "관련 원문/출처",
                subtitle: "확인 기준",
                iconName: "link",
                tint: Color.electricBlue
            )

            HStack(spacing: 10) {
                sourceInfoTile(title: "출처", value: insight.sourceName)
                sourceInfoTile(title: "생성 시각", value: insight.generatedAtText)
            }

            if let sourceURL {
                Text(sourceURL.host ?? sourceURL.absoluteString)
                    .font(.pretendard(12, weight: .semibold))
                    .foregroundStyle(Color.electricBlue)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.electricBlue.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private var loadingState: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ProgressView()
                    .tint(Color.electricBlue)

                Text(mode.loadingMessage)
                    .font(.pretendard(15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
            }

            Text(mode == .quick ? "지금 판단, 핵심 영향, 오늘 확인할 것만 먼저 보여줍니다." : "배경, 자산별 영향, 시나리오, 확인 기준을 함께 보여줍니다.")
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private func errorState(message: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("요약을 불러오지 못했어요")
                .font(.pretendard(17, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            Text(message)
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                viewModel.reloadPresentedInsight(userAssetProfile: userAssetProfile)
            } label: {
                Text("다시 시도")
                    .font(.pretendard(13, weight: .bold))
                    .foregroundStyle(Color.electricBlue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.electricBlue.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    private var bottomActionBar: some View {
        HStack(spacing: 10) {
            Button {
                if let sourceURL {
                    openURL(sourceURL)
                }
            } label: {
                Label(sourceURL == nil ? "원문 링크 없음" : "원문 보기", systemImage: "arrow.up.forward.square")
                    .font(.pretendard(14, weight: .bold))
                    .foregroundStyle(sourceURL == nil ? Color.textDisabled : Color.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        sourceURL == nil ? Color.subtle : Color.brand,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
            }
            .disabled(sourceURL == nil)
            .buttonStyle(PressScaleButtonStyle())

            if mode == .quick {
                Button {
                    viewModel.switchPresentedInsightMode(.detail)
                } label: {
                    Label("자세히 분석", systemImage: "doc.text.magnifyingglass")
                        .font(.pretendard(13, weight: .bold))
                        .foregroundStyle(Color.electricBlue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.hairline, lineWidth: 1)
                        }
                }
                .buttonStyle(PressScaleButtonStyle())
            } else {
                Button {
                    viewModel.toggleSaved(item)
                } label: {
                    Label(viewModel.isSaved(item) ? "저장됨" : "저장", systemImage: viewModel.isSaved(item) ? "bookmark.fill" : "bookmark")
                        .font(.pretendard(13, weight: .bold))
                        .foregroundStyle(viewModel.isSaved(item) ? Color.electricBlue : Color.textTertiary)
                        .frame(width: 108, height: 52)
                        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.hairline, lineWidth: 1)
                        }
                }
                .buttonStyle(PressScaleButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
    }

    private var sourceURL: URL? {
        viewModel.presentedInsight?.sourceURL ?? item.sourceURL
    }

    private func riskRows(from insight: PolicyNewsInsight) -> [String] {
        if insight.riskNotes.isEmpty {
            return ["단일 기사 하나로 정책 집행 시점, 기업 실적, 시장 가격이 동시에 확정되지는 않아요."]
        }

        return insight.riskNotes
    }

    private func quickChecklist(from insight: PolicyNewsInsight) -> [String] {
        let checklist = insight.actionChecklist.isEmpty ? [item.newsroomCheckConditionText] : insight.actionChecklist
        return Array(checklist.prefix(3))
    }

    private var decisionTitle: String {
        switch item.sentiment {
        case .positive:
            return "분할 매수 고려"
        case .neutral:
            return "확인 후 유지"
        case .caution:
            return "추격 매수 보류"
        }
    }

    private var decisionDescription: String {
        switch item.sentiment {
        case .positive:
            return "수혜 가능성은 있지만 원문 숫자와 집행 시점을 확인한 뒤 나눠서 접근하는 편이 적절해요."
        case .neutral:
            return "현재 정보만으로는 즉시 비중을 바꿀 근거가 약해요. 발표 문구와 시장 반응을 확인해도 늦지 않아요."
        case .caution:
            return "가격 변동이 먼저 커질 수 있어요. 확정 숫자와 후속 발표 전까지는 추격 매수보다 점검이 우선이에요."
        }
    }

    private var decisionIconName: String {
        switch item.sentiment {
        case .positive:
            return "cart.badge.plus"
        case .neutral:
            return "pause.circle.fill"
        case .caution:
            return "hand.raised.fill"
        }
    }

    private var decisionTint: Color {
        switch item.sentiment {
        case .positive:
            return Color.emerald
        case .neutral:
            return Color.electricBlue
        case .caution:
            return Color.policyCoral
        }
    }

    private var positiveScenarioText: String {
        switch item.category {
        case .semiconductor:
            return "지원금 집행 시점과 수혜 기업이 명확해지면 관련 ETF 거래대금과 비중 확대 명분이 강해져요."
        case .interestRate:
            return "인하 기대가 커지면 성장주와 채권 ETF가 먼저 반응하고 환율 부담은 완화될 수 있어요."
        case .energy:
            return "예산과 입법 일정이 구체화되면 전력망, 신재생 인프라 자산에 수혜 기대가 붙을 수 있어요."
        default:
            return "정책 방향과 실제 숫자가 함께 확인되면 관련 자산의 모멘텀이 강화될 수 있어요."
        }
    }

    private var negativeScenarioText: String {
        switch item.category {
        case .semiconductor:
            return "집행 지연이나 수혜 기업 불확실성이 남으면 헤드라인만 보고 오른 가격이 되돌릴 수 있어요."
        case .interestRate:
            return "결정문이 매파적으로 해석되면 성장주와 장기채가 동시에 흔들리고 환율 부담이 커질 수 있어요."
        case .energy:
            return "예산 배정이 약하거나 후속 입법이 밀리면 기대만 반영된 종목은 변동성이 커질 수 있어요."
        default:
            return "정책 발표와 실제 집행 사이의 간극이 크면 단기 가격 반응은 다시 되돌려질 수 있어요."
        }
    }

    private func quickBadge(_ title: String) -> some View {
        Text(title)
            .font(.pretendard(10, weight: .bold))
            .foregroundStyle(decisionTint)
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(decisionTint.opacity(0.12), in: Capsule(style: .continuous))
    }

    private func sourceInfoTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.pretendard(10, weight: .bold))
                .foregroundStyle(Color.textTertiary)

            Text(value)
                .font(.pretendard(13, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.subtle.opacity(0.65), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func close() {
        dismiss()
        viewModel.dismissPresentedInsight()
    }
}

private struct InsightSectionHeader: View {
    let title: String
    let subtitle: String
    let iconName: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.pretendard(14, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text(subtitle)
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer()
        }
    }
}

private enum InsightRowStyle {
    case numbered
    case check
    case dot
}

private struct InsightVisualCard: View {
    let title: String
    let subtitle: String
    let iconName: String
    let tint: Color
    let rows: [String]
    let style: InsightRowStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            InsightSectionHeader(title: title, subtitle: subtitle, iconName: iconName, tint: tint)

            VStack(spacing: 8) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    InsightRow(index: index + 1, text: row, tint: tint, style: style)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }
}

private struct InsightRow: View {
    let index: Int
    let text: String
    let tint: Color
    let style: InsightRowStyle

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            indicator
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 16) {
                Text(text)
                    .font(.pretendard(13, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(Color.subtle.opacity(0.65), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var indicator: some View {
        switch style {
        case .numbered:
            Text("\(index)")
                .font(.pretendard(11, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(tint.opacity(0.12), in: Circle())
        case .check:
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.textOnAccent)
                .frame(width: 24, height: 24)
                .background(tint, in: Circle())
        case .dot:
            Circle()
                .fill(tint.opacity(0.7))
                .frame(width: 8, height: 8)
                .frame(width: 24, height: 24)
        }
    }
}

private struct MiniInsightTile: View {
    let index: Int
    let text: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("포인트 \(index)")
                .font(.pretendard(9, weight: .bold))
                .foregroundStyle(tint)

            Text(text)
                .font(.pretendard(12, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .padding(12)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(tint.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct ScenarioTile: View {
    let title: String
    let text: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.pretendard(11, weight: .bold))
                .foregroundStyle(tint)

            Text(text)
                .font(.pretendard(12, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 142, alignment: .topLeading)
        .padding(12)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(tint.opacity(0.14), lineWidth: 1)
        }
    }
}

typealias NewsInsightSheet = PolicyNewsInsightDetailView

#Preview {
    NavigationStack {
        PolicyNewsInsightDetailView(
            item: HomeNewsMockData.items[0],
            userAssetProfile: AppMockData.userAssetProfile,
            viewModel: previewViewModel()
        )
    }
}

@MainActor
private func previewViewModel() -> PolicyNewsViewModel {
    let viewModel = PolicyNewsViewModel(repository: MockPolicyNewsRepository())
    viewModel.presentInsight(for: HomeNewsMockData.items[0], userAssetProfile: AppMockData.userAssetProfile)
    return viewModel
}
