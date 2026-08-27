import SwiftUI

enum NewsroomTickerDigestRow: View {
    case hero(NewsroomHoldingBriefing, onOpenDetail: () -> Void)
    case compact(NewsroomHoldingBriefing, onOpenDetail: () -> Void)
    case quiet(NewsroomHoldingBriefing)

    static func make(for holding: NewsroomHoldingBriefing, onOpenDetail: @escaping () -> Void) -> NewsroomTickerDigestRow {
        switch holding.briefingType {
        case .hero: return .hero(holding, onOpenDetail: onOpenDetail)
        case .compact: return .compact(holding, onOpenDetail: onOpenDetail)
        case .quiet: return .quiet(holding)
        }
    }

    var body: some View {
        switch self {
        case .hero(let holding, let onOpenDetail):
            NewsroomTickerDigestHeroCard(holding: holding, onOpenDetail: onOpenDetail)
        case .compact(let holding, let onOpenDetail):
            NewsroomTickerDigestCompactRow(holding: holding, onOpenDetail: onOpenDetail)
        case .quiet(let holding):
            NewsroomTickerQuietRow(holding: holding)
        }
    }
}

struct NewsroomTickerDigestHeroCard: View {
    let holding: NewsroomHoldingBriefing
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
                    .font(.pretendard(18, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if let summary = holding.summary {
                    Text(summary)
                        .font(.pretendard(13.5, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                impactLine
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .buttonStyle(PressScaleButtonStyle())
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }

    @ViewBuilder
    private var impactLine: some View {
        if let dailyChange = holding.dailyChangePercent {
            HStack(spacing: 5) {
                Text("오늘 \(NewsroomPercentFormat.signed(dailyChange))")
                    .font(.pretendard(12.5, weight: .bold))
                    .foregroundStyle(NewsroomPercentFormat.color(for: dailyChange))

                if let impact = holding.totalAssetImpactPercent {
                    Text("· 총자산 기준 \(NewsroomPercentFormat.signedImpact(impact))")
                        .font(.pretendard(12, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                }
            }
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

    var body: some View {
        HStack(spacing: 11) {
            NewsroomTickerLogo(ticker: holding.ticker, logoURL: holding.logoURL, size: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(holding.ticker) · \(holding.headline ?? "특이사항 없음")")
                    .font(.pretendard(13.5, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                Text(holding.summary ?? "계속 지켜보고 있어요")
                    .font(.pretendard(12.5, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 4)
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
        .accessibilityLabel("\(holding.ticker), \(holding.headline ?? "특이사항 없음"), \(holding.summary ?? "계속 지켜보고 있어요")")
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

enum NewsroomPercentFormat {
    static func signed(_ value: Double) -> String {
        let sign = value > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", value))%"
    }

    static func signedImpact(_ value: Double) -> String {
        let sign = value > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", value))%"
    }

    static func weight(_ value: Double) -> String {
        String(Int(value.rounded()))
    }

    static func color(for value: Double) -> Color {
        if value > 0 { return Color.emerald }
        if value < 0 { return Color.policyCoral }
        return Color.textPrimary
    }
}
