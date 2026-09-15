import SwiftUI

enum NewsroomTickerDigestRow: View {
    case hero(NewsroomHoldingBriefing, isHighlighted: Bool, onOpenDetail: () -> Void)
    case compact(NewsroomHoldingBriefing, onOpenDetail: () -> Void)
    case quiet(NewsroomHoldingBriefing)

    static func make(
        for holding: NewsroomHoldingBriefing,
        isHighlighted: Bool,
        onOpenDetail: @escaping () -> Void
    ) -> NewsroomTickerDigestRow {
        switch holding.briefingType {
        case .hero: return .hero(holding, isHighlighted: isHighlighted, onOpenDetail: onOpenDetail)
        case .compact: return .compact(holding, onOpenDetail: onOpenDetail)
        // Quiet 행은 상세 뉴스가 없는 정적 안내이므로, 열기 동작을 보관하지 않는다.
        case .quiet: return .quiet(holding)
        }
    }

    var body: some View {
        switch self {
        case .hero(let holding, let isHighlighted, let onOpenDetail):
            NewsroomTickerDigestHeroCard(holding: holding, isHighlighted: isHighlighted, onOpenDetail: onOpenDetail)
        case .compact(let holding, let onOpenDetail):
            NewsroomTickerDigestCompactRow(holding: holding, onOpenDetail: onOpenDetail)
        case .quiet(let holding):
            NewsroomTickerQuietRow(holding: holding)
        }
    }
}

struct NewsroomTickerDigestHeroCard: View {
    let holding: NewsroomHoldingBriefing
    let isHighlighted: Bool
    let onOpenDetail: () -> Void

    var body: some View {
        Button(action: onOpenDetail) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    NewsroomTickerLogo(ticker: holding.ticker, logoURL: holding.logoURL, size: 34)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(holding.ticker)
                            .font(.pretendard(13, weight: .bold))
                            .foregroundStyle(Color.textPrimary)

                        Text("내 자산의 \(NewsroomPercentFormat.weight(holding.weightPercent))%")
                            .font(.pretendard(11.5, weight: .semibold))
                            .foregroundStyle(Color.textTertiary)
                    }

                    Spacer(minLength: 6)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.textQuaternary)
                }

                Text(holding.headline ?? holding.name)
                    .font(.pretendard(16, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if let summary = holding.summary.map(NewsroomSummaryText.firstSentence(of:)), !summary.isEmpty {
                    Text(summary)
                        .font(.pretendard(13.5, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                NewsroomHoldingMetrics(holding: holding)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .buttonStyle(PressScaleButtonStyle())
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                .stroke(isHighlighted ? Color.brand : Color.hairline, lineWidth: isHighlighted ? 2 : 1)
        }
    }

}

struct NewsroomTickerDigestCompactRow: View {
    let holding: NewsroomHoldingBriefing
    let onOpenDetail: () -> Void

    var body: some View {
        Button(action: onOpenDetail) {
            HStack(spacing: 11) {
                NewsroomTickerLogo(ticker: holding.ticker, logoURL: holding.logoURL, size: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text(holding.ticker)
                        .font(.pretendard(11.5, weight: .bold))
                        .foregroundStyle(Color.textTertiary)

                    Text(holding.headline ?? holding.name)
                        .font(.pretendard(13.5, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    NewsroomHoldingMetrics(holding: holding)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.textQuaternary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: 58)
        }
        .buttonStyle(PressScaleButtonStyle())
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }
}

struct NewsroomTickerQuietRow: View {
    let holding: NewsroomHoldingBriefing
    static let titleText = "특이사항 없음"
    static let subtitleText = "계속 지켜보고 있어요"

    var body: some View {
        HStack(spacing: 11) {
            NewsroomTickerLogo(ticker: holding.ticker, logoURL: holding.logoURL, size: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text("\(holding.ticker) · 내 자산의 \(NewsroomPercentFormat.weight(holding.weightPercent))%")
                    .font(.pretendard(13, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                Text("\(Self.titleText) · \(Self.subtitleText)")
                    .font(.pretendard(12.5, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(minHeight: 56)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(holding.ticker), 내 자산의 \(NewsroomPercentFormat.weight(holding.weightPercent))%, \(Self.titleText), \(Self.subtitleText)")
    }
}

/// 서버 로고를 우선 표시하고, 네트워크 실패나 URL 부재 시 티커 이니셜로 폴백한다.
struct NewsroomTickerLogo: View {
    let ticker: String
    let logoURL: URL?
    let size: CGFloat

    var body: some View {
        Group {
            if let logoURL {
                AsyncImage(url: logoURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(size * 0.14)
                    } else {
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .background(Color.brandTintBg, in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
        .accessibilityHidden(true)
    }

    private var fallback: some View {
        Text(String(ticker.prefix(1)))
            .font(.pretendard(size * 0.42, weight: .bold))
            .foregroundStyle(Color.brand)
            .frame(width: size, height: size)
    }
}

/// 목록 카드는 요약 전문 대신 첫 문장만 보여준다(전문은 상세 화면에서 읽는다).
/// 마침표를 직접 찾으면 "7.30%"나 "U.S." 같은 값에서 잘리므로 ICU 문장 경계를 쓴다.
enum NewsroomSummaryText {
    static func firstSentence(of summary: String) -> String {
        let trimmed = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        var first: String?
        trimmed.enumerateSubstrings(in: trimmed.startIndex..<trimmed.endIndex, options: .bySentences) { substring, _, _, stop in
            guard let sentence = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !sentence.isEmpty else { return }
            first = sentence
            stop = true
        }
        return first ?? trimmed
    }
}

enum NewsroomPercentFormat {
    static func signed(_ value: Double) -> String {
        let sign = value > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", value))%"
    }

    static func weight(_ value: Double) -> String {
        guard value.isFinite else { return "—" }
        return value.rounded() == value ? String(format: "%.0f", value) : String(format: "%.2f", value)
    }

    static func color(for value: Double) -> Color {
        if value > 0 { return Color.emerald }
        if value < 0 { return Color.policyCoral }
        return Color.textPrimary
    }
}

/// 두 값은 각각 주가의 전일 대비 변화와 현금을 포함한 전체 자산에서의 평가액 비중이다.
private struct NewsroomHoldingMetrics: View {
    let holding: NewsroomHoldingBriefing

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 5) { dailyChange; allocation }
            VStack(alignment: .leading, spacing: 3) { dailyChange; allocation }
        }
    }

    private var dailyChange: some View {
        Text(holding.dailyChangePercent.map { "오늘 \(NewsroomPercentFormat.signed($0))" } ?? "오늘 —")
            .font(.pretendard(12, weight: .bold))
            .foregroundStyle(holding.dailyChangePercent.map(NewsroomPercentFormat.color) ?? Color.textTertiary)
    }

    private var allocation: some View {
        Text("총자산 기준 \(NewsroomPercentFormat.weight(holding.weightPercent))%")
            .font(.pretendard(11.5, weight: .medium))
            .foregroundStyle(Color.textTertiary)
    }
}
