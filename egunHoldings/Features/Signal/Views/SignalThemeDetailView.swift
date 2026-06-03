import SwiftUI

// MARK: - SignalThemeDetailView
//
// Today 탭의 ThemeSignalCard에서 "왜 그런지 알아보기"를 눌렀을 때 표시되는
// 테마 단위 상세 분석 화면. 4개 섹션으로 구성:
//   ① 예측 수치 카드
//   ② 이번 주 눈에 띄는 신호
//   ③ 최근 4주 신호 흐름
//   ④ 다음에 볼 이벤트

struct SignalThemeDetailView: View {
    let detail: SignalThemeDetail

    @Environment(\.dismiss) private var dismiss

    init(theme: PortfolioThemeSignal.Theme) {
        self.detail = SignalThemeDetailMockData.detail(for: theme)
    }

    init(detail: SignalThemeDetail) {
        self.detail = detail
    }

    var body: some View {
        VStack(spacing: 0) {
            navigationHeader

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    PredictionSummaryCard(theme: detail.theme, verdict: detail.verdict, prediction: detail.prediction)

                    signalCardsSection

                    trendTimelineSection

                    if !detail.nextCheckpoints.isEmpty {
                        nextCheckpointSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .background(PSColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Navigation

    private var navigationHeader: some View {
        HStack(alignment: .center) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(PSColor.textPrimary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(detail.theme.displayName)
                .font(.pretendard(20, weight: .bold))
                .foregroundStyle(PSColor.textPrimary)

            Spacer(minLength: 0)

            Text(detail.prediction.asOfDateLabel)
                .font(.pretendard(11, weight: .medium))
                .foregroundStyle(PSColor.textFaint)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(PSColor.surfaceAlt, in: Capsule(style: .continuous))
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(PSColor.background)
    }

    // MARK: ② 이번 주 눈에 띄는 신호

    private var signalCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("이번 주 눈에 띄는 신호")
                .font(.pretendard(17, weight: .bold))
                .foregroundStyle(PSColor.textPrimary)

            if detail.signalCards.isEmpty {
                SignalCardEmptyState(themeName: detail.theme.displayName)
            } else {
                VStack(spacing: 10) {
                    ForEach(detail.signalCards.prefix(4)) { card in
                        SignalCardRow(card: card)
                    }
                }
            }
        }
    }

    // MARK: ③ 최근 4주 신호 흐름

    private var trendTimelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("최근 4주 신호 흐름")
                .font(.pretendard(17, weight: .bold))
                .foregroundStyle(PSColor.textPrimary)

            SignalTrendTimelineCard(points: detail.trendPoints)
        }
    }

    // MARK: ④ 다음에 볼 이벤트

    private var nextCheckpointSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("다음에 볼 이벤트")
                .font(.pretendard(17, weight: .bold))
                .foregroundStyle(PSColor.textPrimary)

            VStack(spacing: 10) {
                ForEach(detail.nextCheckpoints) { checkpoint in
                    NextCheckpointCard(checkpoint: checkpoint)
                }
            }
        }
    }
}

// MARK: - ① 예측 수치 카드

private struct PredictionSummaryCard: View {
    let theme: PortfolioThemeSignal.Theme
    let verdict: PolSignalVerdictKind?
    let prediction: SignalPrediction

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerRow

            Rectangle()
                .fill(PSColor.rule)
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 6) {
                Text("5거래일 후 · \(prediction.targetDateLabel)")
                    .font(.pretendard(12, weight: .medium))
                    .foregroundStyle(PSColor.textFaint)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(prediction.direction.arrowSymbol)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(prediction.direction.color)
                    Text(prediction.returnDisplayText)
                        .font(.pretendard(36, weight: .bold))
                        .foregroundStyle(prediction.direction.color)
                        .monospacedDigit()
                }

                Text(prediction.directionLabel)
                    .font(.pretendard(15, weight: .medium))
                    .foregroundStyle(PSColor.textSecondary)
            }

            priceBox
        }
        .padding(20)
        .background(PSColor.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: PSColor.cardShadow, radius: 8, x: 0, y: 2)
    }

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: theme.sfSymbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.iconColor)
                .frame(width: 40, height: 40)
                .background(theme.iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(theme.displayName)
                .font(.pretendard(20, weight: .bold))
                .foregroundStyle(PSColor.textPrimary)

            Spacer(minLength: 0)

            if let verdict {
                Text(verdict.sentimentLabel)
                    .font(.pretendard(12, weight: .semibold))
                    .foregroundStyle(verdict.sentimentForeground)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(verdict.sentimentSoft, in: Capsule(style: .continuous))
            }
        }
    }

    private var priceBox: some View {
        HStack(spacing: 12) {
            Text("예상 가격")
                .font(.pretendard(12, weight: .medium))
                .foregroundStyle(PSColor.textFaint)

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Text(prediction.currentPriceText)
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(PSColor.textPrimary)
                    .monospacedDigit()

                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(PSColor.textFaint)

                Text(prediction.predictedPriceText)
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(PSColor.textPrimary)
                    .monospacedDigit()

                Text("(\(prediction.priceDeltaText))")
                    .font(.pretendard(13, weight: .medium))
                    .foregroundStyle(prediction.direction.color)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(PSColor.surfaceAlt, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - ② 신호 카드 한 행

private struct SignalCardRow: View {
    let card: SignalThemeDetailCard

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(card.intensity.dotColor)
                    .frame(width: 8, height: 8)
                    .padding(.top, 7)

                VStack(alignment: .leading, spacing: 4) {
                    Text(card.title)
                        .font(.pretendard(15, weight: .semibold))
                        .foregroundStyle(PSColor.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(card.description)
                        .font(.pretendard(13, weight: .regular))
                        .foregroundStyle(PSColor.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(1)
                }

                Spacer(minLength: 8)

                Text(card.intensity.label)
                    .font(.pretendard(11, weight: .semibold))
                    .foregroundStyle(card.intensity.labelColor)
                    .padding(.top, 2)
            }

            if let newsTitle = card.newsTitle {
                Divider()
                    .background(PSColor.rule)
                    .padding(.top, 12)
                    .padding(.bottom, 10)
                    .padding(.leading, 20)

                HStack(spacing: 6) {
                    Image(systemName: "newspaper")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PSColor.textFaint)

                    Text(newsTitle)
                        .font(.pretendard(12, weight: .medium))
                        .foregroundStyle(PSColor.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding(.leading, 20)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(PSColor.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: PSColor.cardShadow, radius: 6, x: 0, y: 1)
    }
}

// MARK: - ② 빈 상태

private struct SignalCardEmptyState: View {
    let themeName: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "minus.circle")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(PSColor.textFaint)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("이번 주는 조용한 한 주예요")
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(PSColor.textPrimary)

                Text("\(themeName) 관련 특이 신호가 감지되지 않았어요.")
                    .font(.pretendard(13, weight: .regular))
                    .foregroundStyle(PSColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(PSColor.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: PSColor.cardShadow, radius: 6, x: 0, y: 1)
    }
}

// MARK: - ③ 신호 추이 타임라인 카드

private struct SignalTrendTimelineCard: View {
    let points: [SignalTrendPoint]

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(points) { point in
                trendColumn(for: point)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 20)
        .background(PSColor.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: PSColor.cardShadow, radius: 6, x: 0, y: 1)
    }

    private func trendColumn(for point: SignalTrendPoint) -> some View {
        VStack(spacing: 10) {
            Text(point.weekLabel)
                .font(.pretendard(11, weight: .medium))
                .foregroundStyle(PSColor.textFaint)

            ZStack {
                if point.isCurrent {
                    Circle()
                        .stroke(PSColor.textPrimary, lineWidth: 2)
                        .frame(width: 18, height: 18)
                }

                Circle()
                    .fill(point.dotColor)
                    .frame(width: point.isCurrent ? 12 : 10, height: point.isCurrent ? 12 : 10)
            }
            .frame(height: 20)

            Text(point.returnDisplayText)
                .font(.pretendard(12, weight: .semibold))
                .foregroundStyle(returnColor(for: point))
                .monospacedDigit()

            if let verdict = point.verdictKind {
                Text(verdict.sentimentLabel)
                    .font(.pretendard(10, weight: .medium))
                    .foregroundStyle(verdict.sentimentForeground)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(verdict.sentimentSoft, in: Capsule(style: .continuous))
                    .lineLimit(1)
                    .fixedSize()
            } else {
                Text("—")
                    .font(.pretendard(10, weight: .medium))
                    .foregroundStyle(PSColor.textFaint)
            }
        }
    }

    private func returnColor(for point: SignalTrendPoint) -> Color {
        guard let returnPct = point.returnPct else { return PSColor.textFaint }
        if returnPct > 0.1 { return PSColor.success }
        if returnPct < -0.1 { return PSColor.danger }
        return PSColor.textSecondary
    }
}

// MARK: - ④ 다음 체크포인트 카드

private struct NextCheckpointCard: View {
    let checkpoint: SignalCheckpoint

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "calendar")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(PSColor.primary)
                .frame(width: 36, height: 36)
                .background(PSColor.primarySoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(checkpoint.dateLabel)
                    .font(.pretendard(12, weight: .semibold))
                    .foregroundStyle(PSColor.primary)

                Text(checkpoint.title)
                    .font(.pretendard(15, weight: .semibold))
                    .foregroundStyle(PSColor.textPrimary)

                Text(checkpoint.description)
                    .font(.pretendard(13, weight: .regular))
                    .foregroundStyle(PSColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(PSColor.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: PSColor.cardShadow, radius: 6, x: 0, y: 1)
    }
}

// MARK: - Preview

#Preview("State A — 빅테크") {
    NavigationStack {
        SignalThemeDetailView(theme: .bigTech)
    }
}

#Preview("State B — 친환경 (조용함)") {
    NavigationStack {
        SignalThemeDetailView(theme: .greenEnergy)
    }
}

#Preview("State C — 반도체 (강한 경고)") {
    NavigationStack {
        SignalThemeDetailView(theme: .semiconductor)
    }
}

#Preview("State D — 금융") {
    NavigationStack {
        SignalThemeDetailView(theme: .financials)
    }
}
