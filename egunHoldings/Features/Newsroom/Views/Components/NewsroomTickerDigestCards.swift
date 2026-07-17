import SwiftUI

/// 종목 다이제스트 카드 3변형 (§1.4). 정렬은 materiality high → low → 조용,
/// 그룹 안에서는 보유 비중 순 (`NewsroomDigest.sortedTickerDigests`).
enum NewsroomTickerDigestRow: View {
    case hero(NewsroomTickerDigest, onOpenDetail: () -> Void)
    case compact(NewsroomTickerDigest, onOpenDetail: () -> Void)
    case quiet(NewsroomTickerDigest)

    /// materiality/hasNews로 변형을 고른다.
    static func make(for digest: NewsroomTickerDigest, onOpenDetail: @escaping () -> Void) -> NewsroomTickerDigestRow {
        guard digest.hasNews else { return .quiet(digest) }

        switch digest.materiality {
        case .high:
            return .hero(digest, onOpenDetail: onOpenDetail)
        case .low, nil:
            return .compact(digest, onOpenDetail: onOpenDetail)
        }
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

// MARK: - A. 히어로 카드 (materiality == high)

struct NewsroomTickerDigestHeroCard: View {
    let digest: NewsroomTickerDigest
    let onOpenDetail: () -> Void

    var body: some View {
        Button(action: onOpenDetail) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 8) {
                    Text(digest.ticker)
                        .font(.pretendard(13, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Text("· 내 자산의 \(digest.portfolioWeightPercent)%")
                        .font(.pretendard(12, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)

                    Spacer(minLength: 4)
                }

                Text(digest.headline ?? digest.name)
                    .font(.pretendard(17, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if let priceChangePercent = digest.priceChangePercent {
                    HStack(spacing: 6) {
                        Text(NewsroomPercentFormat.signed(priceChangePercent))
                            .font(.pretendard(13, weight: .bold))
                            .foregroundStyle(NewsroomPercentFormat.color(for: priceChangePercent))

                        if let impact = digest.portfolioImpactPercent {
                            Text("· 내 총자산 기준 \(NewsroomPercentFormat.signedImpact(impact))")
                                .font(.pretendard(12, weight: .semibold))
                                .foregroundStyle(Color.textTertiary)
                        }
                    }
                }

                HStack(spacing: 12) {
                    if !digest.newFacts.isEmpty {
                        Text("새로 확인된 사실 \(digest.newFacts.count)건")
                            .font(.pretendard(11.5, weight: .semibold))
                            .foregroundStyle(Color.textTertiary)
                    }

                    if !digest.articles.isEmpty {
                        Text("· 근거 기사 \(digest.articles.count)건")
                            .font(.pretendard(11.5, weight: .semibold))
                            .foregroundStyle(Color.textTertiary)
                    }

                    Spacer(minLength: 4)
                }
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
}

// MARK: - B. 컴팩트 로우 (materiality == low)

struct NewsroomTickerDigestCompactRow: View {
    let digest: NewsroomTickerDigest
    let onOpenDetail: () -> Void

    var body: some View {
        Button(action: onOpenDetail) {
            HStack(spacing: 10) {
                Text(digest.ticker)
                    .font(.pretendard(12.5, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 52, alignment: .leading)

                Text(digest.headline ?? digest.name)
                    .font(.pretendard(13.5, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.textQuaternary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: 48)
        }
        .buttonStyle(PressScaleButtonStyle())
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
    }
}

// MARK: - C. 조용 로우 (hasNews == false)

/// 탭 불가 — 상세로 갈 내용이 없다. 셰브런·하이라이트 없음, 회색 처리 금지.
/// 조용함은 실패나 빈 상태가 아니라 능동 감시의 증거(heartbeat)다.
struct NewsroomTickerQuietRow: View {
    let digest: NewsroomTickerDigest

    var body: some View {
        HStack(spacing: 10) {
            Text(digest.ticker)
                .font(.pretendard(12.5, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 52, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(digest.quietStatusText)
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
        .padding(.vertical, 10)
        .frame(minHeight: 48)
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(digest.ticker), \(digest.quietStatusText), 계속 지켜보고 있어요")
    }
}

// MARK: - 등락 포맷 (§3 종목 헤더에서도 재사용)

enum NewsroomPercentFormat {
    static func signed(_ value: Double) -> String {
        let sign = value > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", value))%"
    }

    /// 총자산 환산은 소수 2자리 — "내 총자산 기준 +0.22%" (Mock 레퍼런스 §2 참고값 표기).
    static func signedImpact(_ value: Double) -> String {
        let sign = value > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", value))%"
    }

    /// 오늘탭 규칙 재사용: 상승 emerald, 하락 coral. severity와 별개의 축이다.
    static func color(for value: Double) -> Color {
        if value > 0 { return Color.emerald }
        if value < 0 { return Color.policyCoral }
        return Color.textPrimary
    }
}
