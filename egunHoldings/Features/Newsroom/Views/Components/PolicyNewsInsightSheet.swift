import SwiftUI

struct PolicyNewsInsightSheet: View {
    let item: PolicyNewsItem
    let insight: PolicyNewsInsight?
    let isLoading: Bool
    let errorMessage: String?
    let onRetry: () -> Void
    let isSaved: Bool
    let onToggleSave: () -> Void
    let onHide: () -> Void
    let onSaveCheckpoint: () -> Void

    init(
        item: PolicyNewsItem,
        insight: PolicyNewsInsight?,
        isLoading: Bool,
        errorMessage: String?,
        onRetry: @escaping () -> Void,
        isSaved: Bool = false,
        onToggleSave: @escaping () -> Void = {},
        onHide: @escaping () -> Void = {},
        onSaveCheckpoint: @escaping () -> Void = {}
    ) {
        self.item = item
        self.insight = insight
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.onRetry = onRetry
        self.isSaved = isSaved
        self.onToggleSave = onToggleSave
        self.onHide = onHide
        self.onSaveCheckpoint = onSaveCheckpoint
    }

    var body: some View {
        ZStack {
            Color.elevated.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    if let insight {
                        loadedContent(insight)
                    } else if isLoading {
                        loadingState
                    } else if let errorMessage {
                        errorState(message: errorMessage)
                    } else {
                        loadingState
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.title)
                .font(.pretendard(16, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(item.newsroomSourceTimeText)
                .font(.pretendard(11, weight: .medium))
                .foregroundStyle(Color.mutedForeground.opacity(0.4))
        }
    }

    private func loadedContent(_ insight: PolicyNewsInsight) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sheetTextCard(
                title: "기사 핵심 요약",
                tint: Color.electricBlue.opacity(0.6),
                text: insight.articleSummary.joined(separator: "\n")
            )

            sheetTextCard(
                title: "내 자산 기준 해석",
                tint: Color.emerald.opacity(0.6),
                text: ([insight.portfolioHeadline] + insight.portfolioBullets).joined(separator: "\n")
            )

            sheetTextCard(
                title: "확인해야 할 숫자/문장",
                tint: Color.policyAmber.opacity(0.7),
                text: insight.actionChecklist.isEmpty
                    ? item.newsroomCheckConditionText
                    : insight.actionChecklist.joined(separator: "\n")
            )

            relatedHoldingsCard

            sheetTextCard(
                title: "과도하게 해석하면 안 되는 이유",
                tint: Color.mutedForeground.opacity(0.4),
                text: "단일 기사 하나로 정책 집행 시점, 기업 실적, 시장 가격이 동시에 확정되지는 않아요. 후속 발표와 실제 숫자를 함께 확인해야 합니다."
            )

            NewsInvestmentDisclaimer()
                .padding(.top, 2)

            actionButtons
                .padding(.top, 2)
        }
    }

    private var relatedHoldingsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("관련 보유자산")
                .font(.pretendard(12, weight: .bold))
                .foregroundStyle(Color.textPrimary.opacity(0.65))

            NewsAssetTagFlow(tags: item.newsroomAssetTags)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .softGlassCard()
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button(action: onSaveCheckpoint) {
                Text("체크포인트 저장")
                    .font(.pretendard(12, weight: .bold))
                    .foregroundStyle(Color.electricBlue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        Color.electricBlue.opacity(0.10),
                        in: RoundedRectangle(cornerRadius: KDXRadius.button, style: .continuous)
                    )
            }
            .buttonStyle(PressScaleButtonStyle())

            Button(action: onToggleSave) {
                Label(isSaved ? "저장됨" : "저장", systemImage: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.pretendard(12, weight: .bold))
                    .foregroundStyle(Color.mutedForeground.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        Color.subtle,
                        in: RoundedRectangle(cornerRadius: KDXRadius.button, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: KDXRadius.button, style: .continuous)
                            .stroke(Color.hairline, lineWidth: 1)
                    }
            }
            .buttonStyle(PressScaleButtonStyle())

            Button(action: onHide) {
                Image(systemName: "eye.slash")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.mutedForeground.opacity(0.4))
                    .frame(width: 44, height: 44)
                    .background(
                        Color.subtle,
                        in: RoundedRectangle(cornerRadius: KDXRadius.button, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: KDXRadius.button, style: .continuous)
                            .stroke(Color.hairline, lineWidth: 1)
                    }
            }
            .buttonStyle(PressScaleButtonStyle())
        }
    }

    private var loadingState: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ProgressView()
                    .tint(Color.electricBlue)

                Text("기사와 보유 자산을 바탕으로 맞춤 해설을 만드는 중이에요")
                    .font(.pretendard(13, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
            }

            Text("이 구간은 serverless backend가 OpenAI 응답을 받아 채우는 자리예요.")
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .softGlassCard()
    }

    private func errorState(message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(message)
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Button("다시 시도하기") {
                onRetry()
            }
            .font(.pretendard(13, weight: .bold))
            .foregroundStyle(Color.electricBlue)
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .softGlassCard()
    }

    private func sheetTextCard(title: String, tint: Color, text: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.pretendard(12, weight: .bold))
                .foregroundStyle(tint)

            Text(text)
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(Color.textPrimary.opacity(0.65))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .softGlassCard()
    }
}

typealias NewsInsightSheet = PolicyNewsInsightSheet

#Preview {
    PolicyNewsInsightSheet(
        item: HomeNewsMockData.items[0],
        insight: HomeNewsMockData.insights[HomeNewsMockData.items[0].id],
        isLoading: false,
        errorMessage: nil,
        onRetry: {}
    )
    .presentationDetents([.medium, .large])
}
