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

                GeometryReader { geometry in
                    ScrollView(.vertical, showsIndicators: false) {
                        content
                            .frame(width: max(0, geometry.size.width - 32), alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 24)
                    }
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
            LiquidGlassBackButton(action: close)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(mode.title)
                    .font(.pretendard(13, weight: .bold))
                    .foregroundStyle(modeTint)
                Text(mode.readingTimeText)
                    .font(.pretendard(10, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.horizontal, 12)
            .frame(height: 38)
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
            if let insight = viewModel.presentedInsight {
                loadedContent(insight)
            } else if viewModel.isInsightLoading {
                summaryHeader
                loadingState
            } else if let errorMessage = viewModel.insightErrorMessage {
                summaryHeader
                errorState(message: errorMessage)
            } else {
                summaryHeader
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
            quickLeadCard

            InsightVisualCard(
                title: "핵심 요약",
                subtitle: "3개만 빠르게",
                iconName: "text.alignleft",
                tint: Color.electricBlue,
                rows: quickSummaryRows(from: insight),
                style: .numbered
            )

            industrySnapshotCard

            InsightVisualCard(
                title: "확인 포인트",
                subtitle: "기사에서 볼 숫자",
                iconName: "checklist",
                tint: Color.policyAmber,
                rows: quickChecklist(from: insight),
                style: .check
            )

            sourceInfoCard(insight)

            NewsInvestmentDisclaimer()
                .padding(.top, 2)
        }
    }

    private func detailContent(_ insight: PolicyNewsInsight) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            detailProgressHeader

            summaryHeader

            detailDecisionStrip

            DetailDisclosureCard(
                title: "정책/기사 배경",
                subtitle: "왜 나온 이슈인지",
                iconName: "newspaper.fill",
                tint: Color.electricBlue,
                isExpanded: true
            ) {
                insightRows(insight.articleSummary, tint: Color.electricBlue, style: .numbered)
            }

            DetailDisclosureCard(
                title: "내 보유자산별 영향",
                subtitle: "보유 비중과 연결",
                iconName: "chart.pie.fill",
                tint: Color.emerald,
                isExpanded: true
            ) {
                detailPortfolioContent(insight)
            }

            DetailDisclosureCard(
                title: "긍정/부정 시나리오",
                subtitle: "어느 쪽으로 확인할지",
                iconName: "arrow.left.arrow.right",
                tint: item.newsroomAccentColor
            ) {
                scenarioComparisonContent
            }

            DetailDisclosureCard(
                title: "확인할 숫자와 날짜",
                subtitle: "판단 기준",
                iconName: "checklist",
                tint: Color.policyAmber
            ) {
                insightRows(
                    insight.actionChecklist.isEmpty ? [item.newsroomCheckConditionText] : insight.actionChecklist,
                    tint: Color.policyAmber,
                    style: .check
                )
            }

            DetailDisclosureCard(
                title: "과잉 해석 주의",
                subtitle: "반대로 볼 지점",
                iconName: "exclamationmark.triangle.fill",
                tint: Color.textTertiary
            ) {
                insightRows(riskRows(from: insight), tint: Color.textTertiary, style: .dot)
            }

            DetailDisclosureCard(
                title: "관련 자산 및 출처",
                subtitle: "추가 확인 경로",
                iconName: "link",
                tint: Color.electricBlue
            ) {
                detailSourceContent(insight)
            }

            LearningGuideCard(tint: item.newsroomAccentColor)

            NewsInvestmentDisclaimer()
                .padding(.top, 2)
        }
    }

    private var detailProgressHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("분석 리포트")
                    .font(.pretendard(13, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Text("요약 → 영향 → 시나리오 → 출처")
                    .font(.pretendard(10, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            HStack(spacing: 5) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(index == 0 ? item.newsroomAccentColor : item.newsroomAccentColor.opacity(0.22))
                        .frame(height: 5)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 2)
    }

    private var detailDecisionStrip: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: decisionIconName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(decisionTint)
                .frame(width: 34, height: 34)
                .background(decisionTint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text("요약 판단")
                        .font(.pretendard(11, weight: .bold))
                        .foregroundStyle(decisionTint)
                    Text(mode.subtitle)
                        .font(.pretendard(10, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                }

                Text(decisionTitle)
                    .font(.pretendard(17, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text(decisionDescription)
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(decisionTint.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(decisionTint.opacity(0.15), lineWidth: 1)
        }
    }

    private func detailPortfolioContent(_ insight: PolicyNewsInsight) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(insight.portfolioHeadline)
                .font(.pretendard(15, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            AssetImpactMeterList(tags: item.newsroomAssetTags, tint: item.newsroomAccentColor)

            insightRows(insight.portfolioBullets, tint: Color.emerald, style: .numbered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var scenarioComparisonContent: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            alignment: .leading,
            spacing: 8
        ) {
            ScenarioTile(
                title: "긍정",
                text: positiveScenarioText,
                tint: Color.emerald,
                strength: item.sentiment == .positive ? 0.78 : 0.52
            )

            ScenarioTile(
                title: "부정",
                text: negativeScenarioText,
                tint: Color.policyCoral,
                strength: item.sentiment == .caution ? 0.78 : 0.48
            )
        }
    }

    private func detailSourceContent(_ insight: PolicyNewsInsight) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text("연결 자산")
                    .font(.pretendard(11, weight: .bold))
                    .foregroundStyle(Color.textTertiary)
                NewsAssetTagFlow(tags: item.newsroomAssetTags)
            }

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
    }

    private var quickLeadCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            InsightSectionHeader(
                title: "1분 요약",
                subtitle: "관심 산업 뉴스",
                iconName: item.sentiment.iconName,
                tint: item.newsroomDirectionColor
            )

            Text(item.newsroomIndustryLeadText)
                .font(.pretendard(20, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Text("선택한 관심 산업 기준으로 기사 흐름만 빠르게 정리했어요.")
                .font(.pretendard(13, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(item.newsroomDirectionColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(item.newsroomDirectionColor.opacity(0.16), lineWidth: 1)
        }
    }

    private var industrySnapshotCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            InsightSectionHeader(
                title: "산업 흐름",
                subtitle: item.category.title,
                iconName: item.category.newsroomIconName,
                tint: item.newsroomAccentColor
            )

            Text(item.summary)
                .font(.pretendard(14, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

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
                    viewModel.toggleSaved(item)
                } label: {
                    Label(viewModel.isSaved(item) ? "나중에 보기 추가됨" : "나중에 보기", systemImage: viewModel.isSaved(item) ? "bookmark.fill" : "bookmark")
                        .font(.pretendard(13, weight: .bold))
                        .foregroundStyle(viewModel.isSaved(item) ? Color.electricBlue : Color.textTertiary)
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
                    Label(viewModel.isSaved(item) ? "관심 뉴스 추가됨" : "관심 뉴스에 추가", systemImage: viewModel.isSaved(item) ? "bookmark.fill" : "bookmark")
                        .font(.pretendard(13, weight: .bold))
                        .foregroundStyle(viewModel.isSaved(item) ? Color.electricBlue : Color.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)
                        .frame(width: 142, height: 52)
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

    private func quickSummaryRows(from insight: PolicyNewsInsight) -> [String] {
        let summaryRows = insight.articleSummary.isEmpty ? [item.summary] : insight.articleSummary
        return Array(summaryRows.prefix(3))
    }

    private func insightRows(_ rows: [String], tint: Color, style: InsightRowStyle) -> some View {
        VStack(spacing: 8) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                InsightRow(index: index + 1, text: row, tint: tint, style: style)
            }
        }
    }

    private var decisionTitle: String {
        item.newsroomDecisionTitle
    }

    private var decisionDescription: String {
        item.newsroomDecisionDescription
    }

    private var decisionIconName: String {
        item.newsroomDecisionIconName
    }

    private var decisionTint: Color {
        item.newsroomDecisionColor
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

private struct DetailDisclosureCard<Content: View>: View {
    let title: String
    let subtitle: String
    let iconName: String
    let tint: Color
    private let content: Content

    @State private var isExpanded: Bool

    init(
        title: String,
        subtitle: String,
        iconName: String,
        tint: Color,
        isExpanded: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.tint = tint
        self.content = content()
        _isExpanded = State(initialValue: isExpanded)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            content
                .padding(.top, 14)
        } label: {
            InsightSectionHeader(title: title, subtitle: subtitle, iconName: iconName, tint: tint)
        }
        .tint(tint)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }
}

private struct AssetImpactMeterList: View {
    let tags: [NewsroomAssetTag]
    let tint: Color

    var body: some View {
        VStack(spacing: 9) {
            ForEach(Array(tags.enumerated()), id: \.offset) { index, tag in
                AssetImpactMeterRow(
                    title: tag.title,
                    value: impactValue(for: index),
                    color: tag.color
                )
            }
        }
        .padding(12)
        .background(tint.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func impactValue(for index: Int) -> Double {
        min(0.88, 0.52 + Double(index) * 0.14)
    }
}

private struct AssetImpactMeterRow: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.pretendard(11, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                Spacer()

                Text("\(Int(value * 100))% 연결")
                    .font(.pretendard(10, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.hairline)

                    Capsule(style: .continuous)
                        .fill(color)
                        .frame(width: max(0, proxy.size.width * value))
                }
            }
            .frame(height: 6)
        }
    }
}

private struct LearningGuideCard: View {
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text("학습 가이드")
                    .font(.pretendard(11, weight: .bold))
                    .foregroundStyle(tint)

                Text("이런 정책은 자산에 어떤 영향을 줄까?")
                    .font(.pretendard(14, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text("금리, 보조금, 규제 뉴스가 ETF와 개별 종목에 전달되는 경로를 짧게 복습할 수 있어요.")
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
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

private struct ScenarioTile: View {
    let title: String
    let text: String
    let tint: Color
    let strength: Double

    init(title: String, text: String, tint: Color, strength: Double = 0.58) {
        self.title = title
        self.text = text
        self.tint = tint
        self.strength = strength
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.pretendard(11, weight: .bold))
                    .foregroundStyle(tint)

                Spacer()

                Text("\(Int(strength * 100))%")
                    .font(.pretendard(10, weight: .bold))
                    .foregroundStyle(tint)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(tint.opacity(0.14))

                    Capsule(style: .continuous)
                        .fill(tint)
                        .frame(width: max(0, proxy.size.width * strength))
                }
            }
            .frame(height: 5)

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
