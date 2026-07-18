import SwiftUI

enum NewsroomTickerDigestRow: View {
    case hero(NewsroomTickerDigest, onOpenDetail: () -> Void)
    case compact(NewsroomTickerDigest, onOpenDetail: () -> Void)
    case quiet(NewsroomTickerDigest)

    static func make(
        for digest: NewsroomTickerDigest,
        isHero: Bool,
        onOpenDetail: @escaping () -> Void
    ) -> NewsroomTickerDigestRow {
        guard digest.hasNews else { return .quiet(digest) }
        return isHero ? .hero(digest, onOpenDetail: onOpenDetail) : .compact(digest, onOpenDetail: onOpenDetail)
    }

    var body: some View {
        switch self {
        case .hero(let digest, let onOpenDetail):
            NewsroomTickerDigestHeroCard(digest: digest, onOpenDetail: onOpenDetail)
        case .compact(let digest, let onOpenDetail):
            NewsroomTickerDigestCompactRow(digest: digest, onOpenDetail: onOpenDetail)
        case .quiet(let digest):
            NewsroomTickerQuietRow(digest: digest)
        }
    }
}

struct NewsroomTickerDigestHeroCard: View {
    let digest: NewsroomTickerDigest
    let onOpenDetail: () -> Void

    var body: some View {
        Button(action: onOpenDetail) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    NewsroomTickerLogo(digest: digest, size: 34)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(digest.ticker)
                            .font(.pretendard(13, weight: .bold))
                            .foregroundStyle(Color.textPrimary)

                        Text("내 자산의 \(digest.portfolioWeightPercent)%")
                            .font(.pretendard(11.5, weight: .semibold))
                            .foregroundStyle(Color.textTertiary)
                    }

                    Spacer(minLength: 6)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.textQuaternary)
                }

                Text(digest.headline ?? digest.name)
                    .font(.pretendard(18, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if let subheadline = digest.subheadline {
                    Text(subheadline)
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
        if let priceChange = digest.priceChangePercent {
            HStack(spacing: 5) {
                Text("오늘 \(NewsroomPercentFormat.signed(priceChange))")
                    .font(.pretendard(12.5, weight: .bold))
                    .foregroundStyle(NewsroomPercentFormat.color(for: priceChange))

                if let impact = digest.portfolioImpactPercent {
                    Text("· 총자산 기준 \(NewsroomPercentFormat.signedImpact(impact))")
                        .font(.pretendard(12, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                }
            }
        }
    }
}

struct NewsroomTickerDigestCompactRow: View {
    let digest: NewsroomTickerDigest
    let onOpenDetail: () -> Void

    var body: some View {
        Button(action: onOpenDetail) {
            HStack(spacing: 11) {
                NewsroomTickerLogo(digest: digest, size: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text(digest.ticker)
                        .font(.pretendard(11.5, weight: .bold))
                        .foregroundStyle(Color.textTertiary)

                    Text(digest.subheadline ?? digest.headline ?? digest.name)
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
    let digest: NewsroomTickerDigest

    var body: some View {
        HStack(spacing: 11) {
            NewsroomTickerLogo(digest: digest, size: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(digest.ticker) · \(digest.quietStatusText)")
                    .font(.pretendard(13.5, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                Text("계속 지켜보고 있어요")
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
        .accessibilityLabel("\(digest.ticker), \(digest.quietStatusText), 계속 지켜보고 있어요")
    }
}

struct NewsroomTickerLogo: View {
    let digest: NewsroomTickerDigest
    let size: CGFloat

    var body: some View {
        Group {
            if let logoURL = digest.logoURL {
                AsyncImage(url: logoURL) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
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
        Text(String(digest.ticker.prefix(1)))
            .font(.pretendard(size * 0.42, weight: .bold))
            .foregroundStyle(Color.brand)
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

    static func color(for value: Double) -> Color {
        if value > 0 { return Color.emerald }
        if value < 0 { return Color.policyCoral }
        return Color.textPrimary
    }
}
