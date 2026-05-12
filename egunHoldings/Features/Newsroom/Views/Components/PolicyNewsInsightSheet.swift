import SwiftUI

struct PolicyNewsInsightDetailView: View {
    let item: PolicyNewsItem
    let userAssetProfile: UserAssetProfile
    @ObservedObject var viewModel: PolicyNewsViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

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

            Text("1분 요약")
                .font(.pretendard(13, weight: .bold))
                .foregroundStyle(Color.electricBlue)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(Color.electricBlue.opacity(0.10), in: Capsule(style: .continuous))
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

    private func loadedContent(_ insight: PolicyNewsInsight) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            InsightVisualCard(
                title: "기사 핵심",
                subtitle: "바로 확인할 내용",
                iconName: "newspaper.fill",
                tint: Color.electricBlue,
                rows: insight.articleSummary,
                style: .numbered
            )

            portfolioImpactCard(insight)

            InsightVisualCard(
                title: "확인 포인트",
                subtitle: "매수/매도보다 먼저 볼 것",
                iconName: "checklist",
                tint: Color.policyAmber,
                rows: insight.actionChecklist.isEmpty ? [item.newsroomCheckConditionText] : insight.actionChecklist,
                style: .check
            )

            relatedHoldingsCard

            InsightVisualCard(
                title: "주의할 해석",
                subtitle: "과하게 반응하지 않기",
                iconName: "exclamationmark.triangle.fill",
                tint: Color.textTertiary,
                rows: riskRows(from: insight),
                style: .dot
            )

            NewsInvestmentDisclaimer()
                .padding(.top, 2)
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

    private var loadingState: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ProgressView()
                    .tint(Color.electricBlue)

                Text("맞춤 1분 요약을 만드는 중이에요")
                    .font(.pretendard(15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
            }

            Text("기사 핵심, 내 자산 영향, 확인 포인트 순서로 정리합니다.")
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

            Button {
                viewModel.toggleSaved(item)
            } label: {
                Image(systemName: viewModel.isSaved(item) ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(viewModel.isSaved(item) ? Color.electricBlue : Color.textTertiary)
                    .frame(width: 52, height: 52)
                    .background(Color.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.hairline, lineWidth: 1)
                    }
            }
            .buttonStyle(PressScaleButtonStyle())
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
