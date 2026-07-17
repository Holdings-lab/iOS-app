import SwiftUI

/// 리스트 최상단 상태 브리핑 카드 (§1.2).
/// calm: 정적, 탭 불가 (눌러볼 것을 유도하지 않는다).
/// watch/alert: 좌측 액센트 + 탭 가능 → 시장 스토리 상세로 연결.
/// 톤은 "무슨 일인지 설명해줄게"이지 "위험!"이 아니다 — alert에도 배너·전면 경고 없음.
struct NewsroomBriefingCard: View {
    let digest: NewsroomDigest
    let onOpenMarketStory: () -> Void

    private var isTappable: Bool {
        digest.severity != .calm && digest.marketStory != nil
    }

    var body: some View {
        Group {
            if isTappable {
                Button(action: onOpenMarketStory) {
                    content
                }
                .buttonStyle(PressScaleButtonStyle())
            } else {
                content
            }
        }
        .background(Color.elevated, in: RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous)
                .stroke(Color.hairline, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: KDXRadius.card, style: .continuous))
    }

    private var content: some View {
        HStack(alignment: .center, spacing: 0) {
            if let accent = digest.severity.accentColor {
                Rectangle().fill(accent).frame(width: 4)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(digest.briefingHeadline)
                    .font(.pretendard(17, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(digest.briefingMessage)
                    .font(.pretendard(14, weight: .regular))
                    .foregroundStyle(Color.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                if let cautionText = digest.cautionText {
                    Text(cautionText)
                        .font(.pretendard(12.5, weight: .semibold))
                        .foregroundStyle(digest.severity.accentColor ?? Color.textTertiary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let baseRateText = digest.baseRateText {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.textTertiary)
                            .padding(.top, 2)

                        Text(baseRateText)
                            .font(.pretendard(12, weight: .medium))
                            .foregroundStyle(Color.textTertiary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.muted, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if isTappable {
                    HStack(spacing: 5) {
                        Text("시장 배경 보기")
                            .font(.pretendard(12.5, weight: .bold))

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))

                        Spacer(minLength: 4)
                    }
                    .foregroundStyle(Color.textSecondary)
                    .padding(.top, 2)
                }
            }
            .padding(.vertical, 16)
            .padding(.leading, digest.severity.accentColor == nil ? 16 : 12)
            .padding(.trailing, 16)
        }
    }
}
